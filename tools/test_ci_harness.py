#!/usr/bin/env python3
"""Negative controls for the transcript gate, not numerical correctness proofs."""
from pathlib import Path
from compare_bits import extract, compare

expected = (Path(__file__).resolve().parents[1]/'testdata/expected.bits').read_text()
extract(expected)
controls = ['', expected.splitlines()[0]+'\n', expected+expected.splitlines()[0]+'\n',
            expected.replace('0000000000000000', '0000000000000001', 1),
            expected.replace('0000000000000000', 'xyz', 1),
            '\n'.join(reversed(expected.splitlines()))+'\n']
for text in controls:
    try: compare(expected, extract(text), 'negative-control')
    except ValueError: pass
    else: raise SystemExit('negative control unexpectedly passed')
print(f'All {len(controls)} negative controls rejected')
