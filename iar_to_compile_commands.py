#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从 IAR EWARM 工程文件 (.ewp) 生成 compile_commands.json，供 clangd 做「转到定义」等索引。

用法（在仓库根目录执行）:
  python iar_to_compile_commands.py
  python iar_to_compile_commands.py path/to/project.ewp
  python iar_to_compile_commands.py --chip L471         # L 系列，覆盖 .ewp 里的芯片宏
  python iar_to_compile_commands.py --chip F103         # F 系列
  python iar_to_compile_commands.py -o compile_commands.json
"""

import argparse
import json
import re
import sys
from pathlib import Path


def find_ewp(repo_root):
    ewp_list = sorted(repo_root.rglob("*.ewp"))
    # 优先使用主工程，跳过 Backup 等备份路径
    for p in ewp_list:
        if "Backup" not in p.parts and "backup" not in str(p).lower():
            return p
    return ewp_list[0] if ewp_list else None


def normalize_path(base, raw):
    s = raw.strip()
    # 用 lambda 避免 Windows 路径如 D:\work\... 中的 \w 被 re.sub 当成转义
    s = re.sub(r"\$PROJ_DIR\$", lambda _: str(base), s, flags=re.I)
    s = s.replace("\\", "/")
    return Path(s)


def parse_ewp(ewp_path, repo_root):
    import xml.etree.ElementTree as ET
    tree = ET.parse(ewp_path)
    root = tree.getroot()
    proj_dir = ewp_path.parent
    defines = []
    include_dirs = []
    c_sources = []

    def get_option_states(name):
        for opt in root.iter("option"):
            if opt.find("name") is not None and opt.find("name").text == name:
                return [s.text or "" for s in opt.findall("state") if (s.text or "").strip()]
        return []

    for d in get_option_states("CCDefines"):
        d = d.strip()
        if d:
            defines.append(d)

    for inc in get_option_states("CCIncludePath2"):
        inc = inc.strip()
        if not inc:
            continue
        p = normalize_path(proj_dir, inc)
        try:
            rel = p.resolve().relative_to(repo_root.resolve())
            include_dirs.append(str(rel).replace("\\", "/"))
        except ValueError:
            include_dirs.append(str(p).replace("\\", "/"))

    for fn in root.iter("name"):
        if not fn.text:
            continue
        raw = fn.text.strip()
        if not (raw.endswith(".c") or raw.endswith(".C")):
            continue
        p = normalize_path(proj_dir, raw)
        try:
            rel = p.resolve().relative_to(repo_root.resolve())
            c_sources.append(rel)
        except ValueError:
            c_sources.append(p)

    return defines, include_dirs, c_sources


def parse_chip_arg(chip_str):
    """
    解析 --chip 参数，支持 L 系列（如 L476）和 F 系列（如 F103）。
    返回 (series, number) 或 None（格式错误时）。
    """
    if not chip_str or len(chip_str) < 2:
        return None
    series = chip_str[0].upper()
    if series not in ("L", "F"):
        return None
    if not chip_str[1:].isdigit():
        return None
    return (series, chip_str[1:])


def apply_chip_define(defines, chip):
    """
    若指定 chip（如 L476、F103），则把 defines 中对应系列的芯片宏统一为 STM32{series}{number}xx。
    """
    if not chip:
        return list(defines)
    parsed = parse_chip_arg(chip)
    if not parsed:
        return list(defines)
    series, number = parsed
    chip_define = "STM32{}{}xx".format(series, number)
    if series == "L":
        pattern = re.compile(r"STM32L\d+xx")
    else:
        pattern = re.compile(r"STM32F\d+xx")
    out = []
    replaced = False
    for d in defines:
        if pattern.match(d):
            if not replaced:
                out.append(chip_define)
                replaced = True
            continue
        out.append(d)
    if not replaced:
        out.append(chip_define)
    return out


def build_entries(repo_root, defines, include_dirs, c_sources):
    directory = str(repo_root.resolve())
    extra = [
        "-D__weak=__attribute__((weak))",
        "-D__packed=__attribute__((__packed__))",
        "-target", "arm-none-eabi",
    ]
    entries = []
    for src in c_sources:
        src_str = str(src).replace("\\", "/")
        obj_str = str(src.with_suffix(".o")).replace("\\", "/")
        inc_flags = ["-I" + str((repo_root / inc).resolve()) for inc in include_dirs]
        def_flags = [f"-D{d}" for d in defines]
        parts = ["clang", "-std=c11"] + extra + def_flags + inc_flags + ["-c", "-o", obj_str, src_str]
        command = " ".join(parts)
        entries.append({"directory": directory, "command": command, "file": src_str})
    return entries


def main():
    parser = argparse.ArgumentParser(description="从 IAR .ewp 生成 compile_commands.json")
    parser.add_argument("ewp", nargs="?", default=None, help=".ewp 文件路径，不填则自动查找")
    parser.add_argument("-o", "--out", default="compile_commands.json", help="输出文件路径")
    parser.add_argument("--repo", default=".", help="仓库根目录")
    parser.add_argument(
        "--chip",
        default=None,
        metavar="Sxxx",
        help="芯片型号：L 系列如 L476、L431，F 系列如 F103、F407，覆盖 .ewp 中的芯片宏（仅用于 compile_commands.json）",
    )
    args = parser.parse_args()

    repo_root = Path(args.repo).resolve()
    if not repo_root.is_dir():
        print("错误: 仓库根目录不存在:", repo_root, file=sys.stderr)
        return 1

    if args.ewp:
        ewp_path = Path(args.ewp).resolve()
        if not ewp_path.is_file():
            print("错误: 找不到 .ewp:", ewp_path, file=sys.stderr)
            return 1
    else:
        ewp_path = find_ewp(repo_root)
        if not ewp_path:
            print("错误: 未找到 .ewp，请指定路径", file=sys.stderr)
            return 1
        print("使用工程:", ewp_path, file=sys.stderr)

    defines, include_dirs, c_sources = parse_ewp(ewp_path, repo_root)
    if args.chip:
        parsed = parse_chip_arg(args.chip)
        if not parsed:
            print("错误: --chip 格式应为 L 或 F 系列+型号，如 L476、F103，当前为: {}".format(args.chip), file=sys.stderr)
            return 1
        defines = apply_chip_define(defines, args.chip)
        chip_define = "STM32{}{}xx".format(parsed[0], parsed[1])
        print("芯片宏已设为: {} (--chip {})".format(chip_define, args.chip), file=sys.stderr)
    else:
        print("提示: 未指定 --chip，若需按具体型号索引可添加如 --chip L476 或 --chip F103", file=sys.stderr)
    print("宏:", len(defines), "包含:", len(include_dirs), "C 文件:", len(c_sources), file=sys.stderr)

    entries = build_entries(repo_root, defines, include_dirs, c_sources)
    out_path = Path(args.out)
    if not out_path.is_absolute():
        out_path = repo_root / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2, ensure_ascii=False)
    print("已写入:", out_path, "共", len(entries), "条", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
