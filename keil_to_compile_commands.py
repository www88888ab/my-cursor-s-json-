#!/usr/bin/env python3
"""
Convert Keil MDK-ARM .uvprojx (or legacy .uvproj) to compile_commands.json for
clangd / clang-tidy.

The real firmware build uses Keil ARMCC or AC6; this script does NOT reproduce
the Keil compiler command line. It emits a clang + arm-none-eabi surrogate so
editors and LLVM-based tools get include paths and defines that are close enough
for navigation and optional static analysis.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

SUPPORTED_SRC_SUFFIX = {".c", ".cc", ".cpp", ".cxx", ".C"}

# Keil CPUTYPE("...") -> clang -mcpu=...
_CORTEX_TO_MCPU = {
    "Cortex-M0": "cortex-m0",
    "Cortex-M0+": "cortex-m0plus",
    "Cortex-M23": "cortex-m23",
    "Cortex-M33": "cortex-m33",
    "Cortex-M3": "cortex-m3",
    "Cortex-M4": "cortex-m4",
    "Cortex-M7": "cortex-m7",
    "Cortex-M55": "cortex-m55",
    "Cortex-M85": "cortex-m85",
}


def find_uvproj(repo_root: Path) -> Optional[Path]:
    candidates: List[Path] = []
    for pattern in ("*.uvprojx", "*.uvproj"):
        candidates.extend(sorted(repo_root.rglob(pattern), key=lambda p: str(p).lower()))
    filtered = [p for p in candidates if "backup" not in str(p).lower()]
    if filtered:
        return filtered[0]
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


def expand_keil_vars(raw: str, variables: Dict[str, str]) -> str:
    text = raw
    for key, value in variables.items():
        pattern = re.compile(re.escape(key), flags=re.IGNORECASE)
        text = pattern.sub(value, text)
    return text


def resolve_path(raw: str, base_dir: Path, variables: Dict[str, str]) -> Path:
    expanded = expand_keil_vars(raw, variables)
    normalized = normalize_sep(expanded)
    path = Path(normalized)
    if not path.is_absolute():
        path = base_dir / path
    return path.resolve()


def dedup_sorted(paths: Iterable[Path]) -> List[Path]:
    unique = {p.resolve() for p in paths}
    return sorted(unique, key=lambda p: str(p).lower())


def _text(el: Optional[ET.Element]) -> str:
    if el is None or el.text is None:
        return ""
    return el.text.strip()


def get_selected_target(root: ET.Element, preferred_name: Optional[str]) -> ET.Element:
    targets = root.findall("./Targets/Target")
    if not targets:
        raise ValueError("No <Targets><Target> found in Keil project")
    if not preferred_name:
        return targets[0]
    preferred_lower = preferred_name.strip().lower()
    for tgt in targets:
        name_el = tgt.find("TargetName")
        name = _text(name_el).lower()
        if name == preferred_lower:
            return tgt
    names = [_text(t.find("TargetName")) for t in targets]
    raise ValueError(f'Target "{preferred_name}" not found. Available: {names}')


def parse_cortex_cpu(target: ET.Element) -> Tuple[Optional[str], Optional[str]]:
    """
    Returns (mcpu, mfpu) for clang from <Cpu>... CPUTYPE("...") ... </Cpu>.
    mfpu is set when the string suggests an FPU (e.g. FPU2 on Cortex-M4F).
    """
    cpu_el = target.find("./TargetOption/TargetCommonOption/Cpu")
    cpu_text = _text(cpu_el)
    if not cpu_text:
        return None, None
    m = re.search(r'CPUTYPE\(\s*"([^"]+)"\s*\)', cpu_text)
    if not m:
        return None, None
    ctype = m.group(1).strip()
    mcpu = _CORTEX_TO_MCPU.get(ctype)
    if mcpu is None:
        slug = re.sub(r"^Cortex-", "", ctype, flags=re.I).lower().replace("+", "plus")
        if slug:
            mcpu = f"cortex-{slug}"

    mfpu: Optional[str] = None
    upper = cpu_text.upper()
    if "FPU" in upper or "FPV" in upper:
        if mcpu in ("cortex-m4", "cortex-m7"):
            mfpu = "fpv4-sp-d16" if mcpu == "cortex-m4" else "fpv5-sp-d16"
        elif mcpu in ("cortex-m33", "cortex-m35p"):
            mfpu = "fpv5-sp-d16"

    return mcpu, mfpu


def split_keil_defines(raw: str) -> List[str]:
    if not raw:
        return []
    parts = re.split(r"[,\s]+", raw.strip())
    return [p for p in (x.strip() for x in parts) if p]


def split_keil_includes(raw: str) -> List[str]:
    if not raw:
        return []
    out: List[str] = []
    for chunk in raw.split(";"):
        chunk = chunk.strip()
        if chunk:
            out.append(chunk)
    return out


def extract_c_compiler_options(target: ET.Element) -> Tuple[List[str], List[str]]:
    """Returns (defines, include_path_strings) from Target Cads -> VariousControls."""
    vc = target.find("./TargetOption/TargetArmAds/Cads/VariousControls")
    if vc is None:
        raise ValueError("TargetOption/TargetArmAds/Cads/VariousControls not found (ARMCC layout)")

    define_el = vc.find("Define")
    include_el = vc.find("IncludePath")
    defines = split_keil_defines(_text(define_el))
    includes_raw = split_keil_includes(_text(include_el))
    return defines, includes_raw


def _include_in_build_from_text(text: str) -> bool:
    t = text.strip()
    if t == "0":
        return False
    return True


def group_is_active(group: ET.Element) -> bool:
    opt = group.find("./GroupOption/CommonProperty/IncludeInBuild")
    if opt is not None and opt.text is not None:
        return _include_in_build_from_text(opt.text)
    return True


def file_is_active(file_el: ET.Element) -> bool:
    opt = file_el.find("./FileOption/CommonProperty/IncludeInBuild")
    if opt is not None and opt.text is not None:
        return _include_in_build_from_text(opt.text)
    return True


def collect_sources_from_groups(
    groups_root: Optional[ET.Element],
    uvproj_dir: Path,
    variables: Dict[str, str],
) -> List[Path]:
    if groups_root is None:
        return []
    sources: List[Path] = []

    def walk_group(group: ET.Element) -> None:
        if not group_is_active(group):
            return
        for file_el in group.findall("./Files/File"):
            if not file_is_active(file_el):
                continue
            fp_el = file_el.find("FilePath")
            raw = _text(fp_el)
            if not raw:
                continue
            suffix = Path(normalize_sep(raw)).suffix
            if suffix not in SUPPORTED_SRC_SUFFIX:
                continue
            path = resolve_path(raw, uvproj_dir, variables)
            if path.exists():
                sources.append(path)
        for nested in group.findall("./Group"):
            walk_group(nested)

    for g in groups_root.findall("./Group"):
        walk_group(g)

    return dedup_sorted(sources)


def collect_include_paths(
    include_strings: Sequence[str],
    uvproj_dir: Path,
    variables: Dict[str, str],
) -> List[Path]:
    includes: List[Path] = []
    for raw in include_strings:
        path = resolve_path(raw, uvproj_dir, variables)
        if path.exists():
            includes.append(path)
    return dedup_sorted(includes)


def parse_project(
    uvproj_path: Path,
    target_name: Optional[str],
) -> Tuple[List[str], List[Path], List[Path], Optional[str], Optional[str]]:
    tree = ET.parse(uvproj_path)
    root = tree.getroot()
    uvproj_dir = uvproj_path.parent.resolve()

    variables = {
        "$P": uvproj_dir.as_posix(),
        "$PROJECT_DIR$": uvproj_dir.as_posix(),
        "$PROJ_DIR$": uvproj_dir.as_posix(),
    }

    target = get_selected_target(root, target_name)
    defines, include_raw = extract_c_compiler_options(target)
    includes = collect_include_paths(include_raw, uvproj_dir, variables)

    groups = target.find("Groups")
    sources = collect_sources_from_groups(groups, uvproj_dir, variables)

    mcpu, mfpu = parse_cortex_cpu(target)
    return list(dict.fromkeys(defines)), includes, sources, mcpu, mfpu


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
    mcpu: Optional[str],
    mfpu: Optional[str],
) -> List[Dict[str, object]]:
    directory = repo_root.resolve().as_posix()
    cpu = mcpu or "cortex-m4"
    common_args = [
        "clang",
        "-x",
        "c",
        "-std=c11",
        "-target",
        "arm-none-eabi",
        "-mcpu",
        cpu,
        "-mthumb",
    ]
    if mfpu:
        common_args.extend(["-mfpu", mfpu, "-mfloat-abi", "hard"])
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
    parser = argparse.ArgumentParser(description="Generate compile_commands.json from Keil .uvprojx / .uvproj")
    parser.add_argument("uvproj", nargs="?", default=None, help="Path to .uvprojx (auto-detect if omitted)")
    parser.add_argument("--repo", default=".", help="Repository root directory")
    parser.add_argument("-o", "--out", default="compile_commands.json", help="Output JSON path")
    parser.add_argument("--target", default=None, help="Keil target name (Configuration / TargetName)")
    parser.add_argument("--chip", default=None, help="Override STM32 family define, e.g. L431 or F103")
    parser.add_argument(
        "--mcpu",
        default=None,
        help="Override clang -mcpu (default: parsed from project Cpu, else cortex-m4)",
    )
    parser.add_argument(
        "--mfpu",
        default=None,
        help="Override -mfpu (default: from project when FPU is indicated; omit to skip float ABI flags)",
    )
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

    if args.uvproj:
        uvproj_path = Path(args.uvproj).resolve()
    else:
        uvproj_path = find_uvproj(repo_root)
        if uvproj_path is None:
            print("Error: no .uvprojx / .uvproj file found under repo root.", file=sys.stderr)
            return 1

    if not uvproj_path.is_file():
        print(f"Error: Keil project file not found: {uvproj_path}", file=sys.stderr)
        return 1

    try:
        defines, include_dirs, sources, parsed_mcpu, parsed_mfpu = parse_project(uvproj_path, args.target)
    except Exception as exc:
        print(f"Error: failed parsing Keil project: {exc}", file=sys.stderr)
        return 1

    mcpu = args.mcpu.strip() if args.mcpu else parsed_mcpu
    mfpu = args.mfpu.strip() if args.mfpu else parsed_mfpu

    if args.chip:
        if not parse_chip_arg(args.chip):
            print(f"Error: invalid --chip value: {args.chip}", file=sys.stderr)
            return 1
    defines = apply_chip_define(defines, args.chip)

    if not sources:
        print("Error: no source files extracted from Keil project", file=sys.stderr)
        return 1
    if not include_dirs:
        print("Warning: no include directories extracted from Keil project", file=sys.stderr)

    toolchain = resolve_gcc_toolchain(args.gcc_toolchain)
    if toolchain is None:
        print(
            "Warning: no --gcc-toolchain / ARM_GNU_GCC_TOOLCHAIN: clang-tidy may miss <math.h> and libc headers.",
            file=sys.stderr,
        )
    entries = build_entries(
        repo_root,
        defines,
        include_dirs,
        sources,
        args.input_charset,
        toolchain,
        mcpu,
        mfpu,
    )

    out_path = Path(args.out)
    if not out_path.is_absolute():
        out_path = repo_root / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as fp:
        json.dump(entries, fp, indent=2, ensure_ascii=False)

    print(f"Keil project: {uvproj_path}")
    print(f"Defines: {len(defines)}, Includes: {len(include_dirs)}, Sources: {len(sources)}")
    print(f"mcpu={mcpu!r}, mfpu={mfpu!r}")
    print(f"Generated: {out_path} ({len(entries)} entries)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
