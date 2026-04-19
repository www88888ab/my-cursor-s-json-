#!/usr/bin/env python3
"""
Convert IAR EWARM .ewp project to compile_commands.json for clangd / clang-tidy.

The real firmware build uses IAR (EWARM); this script does NOT reproduce the
IAR compiler command line. It emits a clang + arm-none-eabi surrogate so editors
and LLVM-based tools get include paths and defines that are close enough for
navigation and optional static analysis.
"""

import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple


SUPPORTED_SRC_SUFFIX = {".c", ".cc", ".cpp", ".cxx", ".C"}


def find_ewp(repo_root: Path) -> Optional[Path]:
    candidates = sorted(repo_root.rglob("*.ewp"), key=lambda p: str(p).lower())
    for path in candidates:
        lower = str(path).lower()
        if "backup" not in lower:
            return path
    return candidates[0] if candidates else None


def parse_chip_arg(chip: str) -> Optional[Tuple[str, str]]:
    if not chip or len(chip) < 2:
        return None
    series = chip[0].upper()
    number = chip[1:]
    if series not in ("L", "F") or not number.isdigit():
        return None
    return series, number


def apply_chip_define(defines: Sequence[str], chip: Optional[str]) -> List[str]:
    if not chip:
        return list(dict.fromkeys(defines))

    parsed = parse_chip_arg(chip)
    if not parsed:
        return list(dict.fromkeys(defines))

    series, number = parsed
    replacement = f"STM32{series}{number}xx"
    family_pattern = re.compile(rf"^STM32{series}\d+xx$")

    out: List[str] = []
    replaced = False
    for item in defines:
        if family_pattern.match(item):
            if not replaced:
                out.append(replacement)
                replaced = True
            continue
        out.append(item)
    if not replaced:
        out.append(replacement)

    return list(dict.fromkeys(out))


def normalize_sep(path_str: str) -> str:
    return path_str.replace("\\", "/").strip()


def expand_iar_vars(raw: str, variables: Dict[str, str]) -> str:
    text = raw
    for key, value in variables.items():
        pattern = re.compile(re.escape(key), flags=re.IGNORECASE)
        text = pattern.sub(value, text)
    return text


def resolve_path(raw: str, base_dir: Path, variables: Dict[str, str]) -> Path:
    expanded = expand_iar_vars(raw, variables)
    normalized = normalize_sep(expanded)
    path = Path(normalized)
    if not path.is_absolute():
        path = base_dir / path
    return path.resolve()


def dedup_sorted(paths: Iterable[Path]) -> List[Path]:
    unique = {p.resolve() for p in paths}
    return sorted(unique, key=lambda p: str(p).lower())


def get_selected_configuration(root: ET.Element, preferred_name: Optional[str]) -> ET.Element:
    configs = root.findall("./configuration")
    if not configs:
        raise ValueError("No <configuration> found in .ewp")
    if not preferred_name:
        return configs[0]
    preferred_lower = preferred_name.strip().lower()
    for cfg in configs:
        name_node = cfg.find("./name")
        cfg_name = (name_node.text or "").strip().lower() if name_node is not None else ""
        if cfg_name == preferred_lower:
            return cfg
    raise ValueError(f'Configuration "{preferred_name}" not found in .ewp')


def read_option_states(settings_node: ET.Element, option_name: str) -> List[str]:
    for opt in settings_node.findall(".//option"):
        name_node = opt.find("name")
        if name_node is not None and (name_node.text or "").strip() == option_name:
            values = []
            for state in opt.findall("state"):
                text = (state.text or "").strip()
                if text:
                    values.append(text)
            return values
    return []


def extract_iccarm_settings(configuration: ET.Element) -> ET.Element:
    for settings in configuration.findall("./settings"):
        name_node = settings.find("name")
        if name_node is not None and (name_node.text or "").strip() == "ICCARM":
            return settings
    raise ValueError("ICCARM settings not found in selected configuration")


def collect_sources(root: ET.Element, ewp_dir: Path, variables: Dict[str, str]) -> List[Path]:
    sources: List[Path] = []
    for node in root.findall(".//file/name"):
        raw = (node.text or "").strip()
        if not raw:
            continue
        suffix = Path(normalize_sep(raw)).suffix
        if suffix not in SUPPORTED_SRC_SUFFIX:
            continue
        path = resolve_path(raw, ewp_dir, variables)
        if path.exists():
            sources.append(path)
    return dedup_sorted(sources)


def collect_includes(iccarm_settings: ET.Element, ewp_dir: Path, variables: Dict[str, str]) -> List[Path]:
    includes: List[Path] = []
    for raw in read_option_states(iccarm_settings, "CCIncludePath2"):
        path = resolve_path(raw, ewp_dir, variables)
        if path.exists():
            includes.append(path)
    return dedup_sorted(includes)


def parse_project(
    ewp_path: Path,
    config_name: Optional[str],
) -> Tuple[List[str], List[Path], List[Path]]:
    tree = ET.parse(ewp_path)
    root = tree.getroot()
    ewp_dir = ewp_path.parent.resolve()

    variables = {
        "$PROJ_DIR$": ewp_dir.as_posix(),
        "$PROJECT_DIR$": ewp_dir.as_posix(),
    }

    configuration = get_selected_configuration(root, config_name)
    iccarm_settings = extract_iccarm_settings(configuration)

    defines = read_option_states(iccarm_settings, "CCDefines")
    includes = collect_includes(iccarm_settings, ewp_dir, variables)
    sources = collect_sources(root, ewp_dir, variables)
    return list(dict.fromkeys(defines)), includes, sources


def resolve_gcc_toolchain(explicit: Optional[str]) -> Optional[Path]:
    """Root directory of GNU Arm Embedded (contains bin/arm-none-eabi-gcc and arm-none-eabi/include)."""
    if explicit:
        text = explicit.strip()
        if text:
            p = Path(text).resolve()
            if p.is_dir():
                return p
    for key in ("ARM_GNU_GCC_TOOLCHAIN", "GNU_ARM_TOOLCHAIN_PATH", "ARM_TOOLCHAIN_ROOT"):
        raw = os.environ.get(key, "").strip()
        if not raw:
            continue
        p = Path(raw).resolve()
        if p.is_dir():
            return p
    return None


def build_entries(
    repo_root: Path,
    defines: Sequence[str],
    includes: Sequence[Path],
    sources: Sequence[Path],
    input_charset: str,
    gcc_toolchain: Optional[Path],
) -> List[Dict[str, object]]:
    directory = repo_root.resolve().as_posix()
    common_args = [
        "clang",
        "-x",
        "c",
        "-std=c11",
        "-target",
        "arm-none-eabi",
        "-mcpu=cortex-m4",
        "-mthumb",
    ]
    if gcc_toolchain is not None:
        common_args.append(f"--gcc-toolchain={gcc_toolchain.as_posix()}")
    common_args.append(f"-finput-charset={input_charset}")
    common_args.extend(
        [
            "-D__weak=__attribute__((weak))",
            "-D__packed=__attribute__((__packed__))",
            "-D__STATIC_INLINE=static inline",
        ]
    )
    common_args.extend(f"-D{item}" for item in defines)
    common_args.extend(f"-I{item.as_posix()}" for item in includes)

    entries: List[Dict[str, object]] = []
    for src in sources:
        src_abs = src.resolve().as_posix()
        src_rel = src.resolve().relative_to(repo_root.resolve()).as_posix()
        obj_rel = (Path(".clangd/obj") / Path(src_rel).with_suffix(".o")).as_posix()
        args = [*common_args, "-c", src_abs, "-o", obj_rel]
        entries.append(
            {
                "directory": directory,
                "file": src_abs,
                "arguments": args,
            }
        )
    return entries


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate compile_commands.json from IAR .ewp")
    parser.add_argument("ewp", nargs="?", default=None, help="Path to .ewp (auto-detect if omitted)")
    parser.add_argument("--repo", default=".", help="Repository root directory")
    parser.add_argument("-o", "--out", default="compile_commands.json", help="Output JSON path")
    parser.add_argument("--config", default=None, help="IAR configuration name")
    parser.add_argument("--chip", default=None, help="Override STM32 family define, e.g. L431 or F103")
    parser.add_argument(
        "--input-charset",
        default="UTF-8",
        help="Source file charset for clang (use UTF-8 for LLVM; 'gbk' is often rejected)",
    )
    parser.add_argument(
        "--gcc-toolchain",
        default=None,
        help="GNU Arm Embedded toolchain root (parent of arm-none-eabi/). "
        "Also reads env ARM_GNU_GCC_TOOLCHAIN / GNU_ARM_TOOLCHAIN_PATH / ARM_TOOLCHAIN_ROOT.",
    )
    args = parser.parse_args()

    repo_root = Path(args.repo).resolve()
    if not repo_root.is_dir():
        print(f"Error: invalid repo directory: {repo_root}", file=sys.stderr)
        return 1

    if args.ewp:
        ewp_path = Path(args.ewp).resolve()
    else:
        ewp_path = find_ewp(repo_root)
        if ewp_path is None:
            print("Error: no .ewp file found under repo root.", file=sys.stderr)
            return 1

    if not ewp_path.is_file():
        print(f"Error: .ewp file not found: {ewp_path}", file=sys.stderr)
        return 1

    try:
        defines, include_dirs, sources = parse_project(ewp_path, args.config)
    except Exception as exc:
        print(f"Error: failed parsing .ewp: {exc}", file=sys.stderr)
        return 1

    if args.chip:
        if not parse_chip_arg(args.chip):
            print(f"Error: invalid --chip value: {args.chip}", file=sys.stderr)
            return 1
    defines = apply_chip_define(defines, args.chip)

    if not sources:
        print("Error: no source files extracted from .ewp", file=sys.stderr)
        return 1
    if not include_dirs:
        print("Warning: no include directories extracted from .ewp", file=sys.stderr)

    toolchain = resolve_gcc_toolchain(args.gcc_toolchain)
    if toolchain is None:
        print(
            "Warning: no --gcc-toolchain / ARM_GNU_GCC_TOOLCHAIN: clang-tidy may miss <math.h> and libc headers.",
            file=sys.stderr,
        )
    entries = build_entries(repo_root, defines, include_dirs, sources, args.input_charset, toolchain)

    out_path = Path(args.out)
    if not out_path.is_absolute():
        out_path = repo_root / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as fp:
        json.dump(entries, fp, indent=2, ensure_ascii=False)

    print(f"EWP: {ewp_path}")
    print(f"Defines: {len(defines)}, Includes: {len(include_dirs)}, Sources: {len(sources)}")
    print(f"Generated: {out_path} ({len(entries)} entries)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
