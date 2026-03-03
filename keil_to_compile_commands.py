#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
从 Keil MDK 工程文件 (.uvprojx) 生成 compile_commands.json，供 clangd 做「转到定义」等索引。

用法（在仓库根目录执行）:
  python keil_to_compile_commands.py
  python keil_to_compile_commands.py path/to/project.uvprojx
  python keil_to_compile_commands.py -o compile_commands.json
"""

import argparse
import json
import re
import sys
from pathlib import Path


def find_uvprojx(repo_root):
    """优先使用主工程，跳过 Backup 等备份路径"""
    uvprojx_list = sorted(repo_root.rglob("*.uvprojx"))
    uvproj_list = sorted(repo_root.rglob("*.uvproj"))
    all_projs = uvprojx_list + uvproj_list
    # 优先使用主工程，跳过 Backup 等备份路径
    for p in all_projs:
        if "Backup" not in p.parts and "backup" not in str(p).lower():
            return p
    return all_projs[0] if all_projs else None


def normalize_path(proj_dir, raw):
    """将 Keil 工程路径中的 $PROJ_DIR$ 替换为实际项目目录"""
    s = raw.strip()
    # 用 lambda 避免 Windows 路径如 D:\work\... 中的 \w 被 re.sub 当成转义
    s = re.sub(r"\$PROJ_DIR\$", lambda _: str(proj_dir), s, flags=re.I)
    s = s.replace("\\", "/")
    return Path(s)


def get_text(elem, default=""):
    """获取 XML 元素的文本内容，支持默认值"""
    if elem is not None and elem.text:
        return elem.text.strip()
    return default


def parse_uvprojx(uvprojx_path, repo_root):
    """解析 Keil .uvprojx 工程文件，获取 Define 和 IncludePath"""
    import xml.etree.ElementTree as ET

    tree = ET.parse(uvprojx_path)
    root = tree.getroot()
    proj_dir = uvprojx_path.parent
    defines = []
    include_dirs = []
    c_sources = []

    # 从 TargetArmAds/Cads/VariousControls 获取 Define 和 IncludePath
    target_cads = root.find(".//TargetArmAds/Cads")
    if target_cads is not None:
        vc = target_cads.find("VariousControls")
        if vc is not None:
            for d in get_text(vc.find("Define")).split(","):
                d = d.strip()
                if d:
                    defines.append(d)
            for inc in get_text(vc.find("IncludePath")).split(";"):
                inc = inc.strip()
                if not inc:
                    continue
                p = (proj_dir / normalize_path(proj_dir, inc)).resolve()
                try:
                    rel = p.relative_to(repo_root.resolve())
                    include_dirs.append(str(rel).replace("\\", "/"))
                except ValueError:
                    include_dirs.append(str(p).replace("\\", "/"))

    # 去重并排序
    defines = list(dict.fromkeys(defines))
    include_dirs = list(dict.fromkeys(include_dirs))

    # 筛选出 FileType=1 的 C 文件
    for f in root.iter("File"):
        ftype = f.find("FileType")
        if ftype is None or get_text(ftype) != "1":
            continue
        # 优先使用 FilePath，否则使用 FileName
        path_elem = f.find("FilePath")
        name_elem = f.find("FileName")
        raw = get_text(path_elem) or get_text(name_elem)
        if not raw or not (raw.lower().endswith(".c")):
            continue
        p = (proj_dir / normalize_path(proj_dir, raw)).resolve()
        try:
            rel = p.relative_to(repo_root.resolve())
            c_sources.append(rel)
        except ValueError:
            c_sources.append(p)

    return defines, include_dirs, c_sources


def build_entries(repo_root, defines, include_dirs, c_sources):
    """构建 compile_commands.json 条目"""
    directory = str(repo_root.resolve())
    extra = [
        "-D__weak=__attribute__((weak))",
        "-D__packed=__attribute__((__packed__))",
        "-target", "arm-none-eabi",
    ]
    entries = []
    for src in c_sources:
        src_str = str(src).replace("\\", "/")
        obj_str = str(Path(src_str).with_suffix(".o")).replace("\\", "/")
        inc_flags = ["-I" + str((repo_root / inc).resolve()) for inc in include_dirs]
        def_flags = [f"-D{d}" for d in defines]
        parts = ["clang", "-std=c11"] + extra + def_flags + inc_flags + ["-c", "-o", obj_str, src_str]
        command = " ".join(parts)
        entries.append({"directory": directory, "command": command, "file": src_str})
    return entries


def main():
    parser = argparse.ArgumentParser(description="从 Keil .uvprojx 生成 compile_commands.json")
    parser.add_argument("uvprojx", nargs="?", default=None, help=".uvprojx 文件路径，不填则自动查找")
    parser.add_argument("-o", "--out", default="compile_commands.json", help="输出文件路径")
    parser.add_argument("--repo", default=".", help="仓库根目录")
    args = parser.parse_args()

    repo_root = Path(args.repo).resolve()
    if not repo_root.is_dir():
        print("错误: 仓库根目录不存在:", repo_root, file=sys.stderr)
        return 1

    if args.uvprojx:
        uvprojx_path = Path(args.uvprojx).resolve()
        if not uvprojx_path.is_file():
            print("错误: 找不到工程文件:", uvprojx_path, file=sys.stderr)
            return 1
    else:
        uvprojx_path = find_uvprojx(repo_root)
        if not uvprojx_path:
            print("错误: 未找到 .uvprojx 或 .uvproj，请指定路径", file=sys.stderr)
            return 1
        print("使用工程:", uvprojx_path, file=sys.stderr)

    defines, include_dirs, c_sources = parse_uvprojx(uvprojx_path, repo_root)
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
