#!/usr/bin/env python3
"""Run debug/release tests and persist auditable bit and compiler transcripts."""
import argparse
from pathlib import Path
import shlex
import subprocess
from compare_bits import extract, compare

ROOT = Path(__file__).resolve().parents[1]

def run(command, log):
    result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    log.write_text(result.stdout)
    print(result.stdout, end="")
    if result.returncode:
        raise SystemExit(result.returncode)
    return result.stdout

def main():
    parser = argparse.ArgumentParser(); parser.add_argument('backend', choices=['wasm','wasm-gc','js','native']); parser.add_argument('--compiler'); args = parser.parse_args()
    out = ROOT/'_build/ci'; out.mkdir(parents=True, exist_ok=True)
    expected = (ROOT/'testdata/expected.bits').read_text()
    for mode in ['debug', 'release']:
        target_dir = ROOT/f'_build/ci-{args.backend}-{mode}'
        command = ['moon', 'test', '--target', args.backend, '--deny-warn', '--verbose', '--no-parallelize', '--target-dir', str(target_dir)]
        if mode == 'release': command.append('--release')
        if args.backend == 'native':
            plan = run(command+['--dry-run'], out/f'{mode}-native-build-plan.log')
            compiler_lines = [line for line in plan.splitlines() if ' -o ' in line and '.exe' in line and ('.c ' in line or '.o ' in line)]
            if not compiler_lines or any('-ffp-contract=off' not in line for line in compiler_lines):
                raise SystemExit('native artifact missing -ffp-contract=off')
            if args.compiler and any(shlex.split(line)[0] != args.compiler for line in compiler_lines):
                raise SystemExit('native artifact compiled with unexpected compiler')
        text = run(command, out/f'{args.backend}-{mode}.log')
        bits = extract(text); compare(expected, bits, f'{args.backend}-{mode}')
        (out/f'{args.backend}-{mode}.bits').write_text(bits)

if __name__ == '__main__': main()
