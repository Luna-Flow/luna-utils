#!/usr/bin/env python3
"""Fail when a public function is not exercised by the randomized audit.

The public names come from the generated `.mbti` files, the exercised names from
the generated audit test. A new public function must be assigned to an audit
family here and called by the generator, or listed in EXEMPT with a reason.

    python3 tools/api_audit.py
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGES = {"@float": "src/float/pkg.generated.mbti", "@binary32": "src/float/binary32/pkg.generated.mbti"}
EXEMPT = {}  # name -> reason; keep empty unless a function cannot be compared with an exact model


def public_functions(path):
    return re.findall(r"^pub fn (\w+)\(", (ROOT / path).read_text(), re.M)


def main():
    generated = subprocess.run([sys.executable, str(ROOT / "tools/random_audit.py"), "--seed", "1", "--count", "8"],
                               check=True, capture_output=True, text=True).stdout
    missing = []
    total = 0
    for prefix, mbti in PACKAGES.items():
        for name in public_functions(mbti):
            total += 1
            if name in EXEMPT:
                continue
            if f"{prefix}.{name}(" not in generated:
                missing.append(f"{prefix}.{name}")
    if missing:
        print("public functions without audit coverage:", *missing, sep="\n  ")
        return 1
    print(f"api audit: {total} public functions, all exercised by the randomized audit")
    return 0


if __name__ == "__main__":
    sys.exit(main())
