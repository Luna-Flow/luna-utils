#!/usr/bin/env python3
"""CI-only compiler selection; modify existing policy without changing defaults."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser(); parser.add_argument('compiler', choices=['gcc','clang']); args = parser.parse_args()
compiler = shutil.which(args.compiler)
if not compiler: raise SystemExit(f"missing compiler: {args.compiler}")
subprocess.run([compiler, '--version'], check=True)
root = Path(__file__).resolve().parents[1]
for path in sorted((root/'src').rglob('moon.pkg')):
    text = path.read_text()
    if '"cc-flags"' not in text or '-ffp-contract=off' not in text:
        raise SystemExit(f"native FP policy missing: {path}")
    text = text.replace('"cc-flags":', f'"cc": {json.dumps(compiler)},\n      "cc-flags":')
    # Exercise FMA-capable host instructions instead of x86-64 baseline.
    text = text.replace('-ffp-contract=off', '-march=native -ffp-contract=off')
    path.write_text(text)
print(compiler)
