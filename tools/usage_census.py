#!/usr/bin/env python3
"""Count which numeric types, containers and operations Luna-Flow sources use.

The compiler matrix (tools/compiler_matrix.py) covers what this census shows in
use. Re-run it when the sources change and compare with the matrix lists.

    python3 tools/usage_census.py [REPO_DIR ...]      # default: sibling repositories
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIP = ("_build", ".mooncakes", "_worktrees", "_test.mbt", "_wbtest.mbt", "ci_probe", "/target/")
TYPES = ["Int", "UInt", "Int64", "UInt64", "Int16", "UInt16", "Byte", "Float", "Double", "Char", "Bool"]
OPS = [("reinterpret_as_", r"reinterpret_as_"), ("to_uint64()", r"\.to_uint64\(\)"), ("to_int64()", r"\.to_int64\(\)"),
       ("to_double()", r"\.to_double\(\)"), ("to_int()", r"\.to_int\(\)"), ("to_uint()", r"\.to_uint\(\)"),
       ("shift >>", r">>"), ("shift <<", r"<<"), ("clz/ctz/popcnt", r"\.(clz|ctz|popcnt)\(\)"),
       ("from_int64/uint64", r"from_u?int64"), ("Array::get", r"\.get\(")]


def sources(dirs):
    for d in dirs:
        for f in Path(d).rglob("*.mbt"):
            if not any(k in str(f) for k in SKIP):
                yield f.read_text(errors="ignore")


def main():
    base = ROOT.parent.parent if ROOT.parent.name == "_worktrees" else ROOT.parent
    dirs = sys.argv[1:] or [p for p in base.iterdir() if p.is_dir() and (p / "moon.mod").exists() and p.name != ROOT.name]
    text = "\n".join(sources(dirs))
    print(f"{len(list(sources(dirs)))} source files in {len(dirs)} directories\n")
    print("Type      Option  Array/FixedArray  tuple  Ref")
    for t in TYPES:
        opt = len(re.findall(rf"\b{t}\?", text))
        arr = len(re.findall(rf"(?:Array|FixedArray|ArrayView|MutArrayView)\[{t}\]", text))
        tup = len(re.findall(rf"\({t}, |, {t}\)", text))
        ref = len(re.findall(rf"Ref\[{t}\]", text))
        print(f"{t:9}{opt:7}{arr:18}{tup:7}{ref:5}")
    print("\nOperation              uses")
    for name, pat in OPS:
        print(f"{name:22}{len(re.findall(pat, text))}")


if __name__ == "__main__":
    main()
