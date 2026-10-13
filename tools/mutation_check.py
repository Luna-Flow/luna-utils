#!/usr/bin/env python3
"""Mutation check of the audit platform: inject known bugs, expect the audit to notice.

Each mutation edits one source line, runs the ci_probe package on one backend and
restores the file. A mutation is `caught` when the randomized audit reports a
mismatch, `caught-by-suite` when only another test fails, and `SURVIVED` when
everything still passes (a hole in the audit).

    python3 tools/mutation_check.py --backend js --seed 7 --count 600
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
F = "src/float/"
B = "src/float/binary32/"
MUTATIONS = [
    ("minimum selects +0 for mixed zeros", F + "ordering.mbt", "(xb | yb).reinterpret_as_double()", "(xb & yb).reinterpret_as_double()"),
    ("maximum selects -0 for mixed zeros", F + "ordering.mbt", "(xb & yb).reinterpret_as_double()", "(xb | yb).reinterpret_as_double()"),
    ("totalOrder key off by one bit", F + "ordering.mbt", "0x7fffffffffffffffUL } else", "0x7ffffffffffffffeUL } else"),
    ("roundToIntegral below one: ties to even ignores the exact half", F + "rounding.mbt", "unbiased == -1 && fraction != 0UL", "unbiased == -1"),
    ("roundToIntegral ties-to-even picks the odd neighbour", F + "rounding.mbt", "(kept & (1UL << discarded)) != 0UL", "(kept & (1UL << discarded)) == 0UL"),
    ("roundToIntegral ties-away uses a strict half", F + "rounding.mbt", "remainder >= 1UL << (discarded - 1)", "remainder > 1UL << (discarded - 1)"),
    ("Int checked range accepts 2^31", F + "conversions.mbt", "y >= 2147483648.0 || y < -2147483648.0", "y > 2147483648.0 || y < -2147483648.0"),
    ("UInt64 checked range accepts 2^64", F + "conversions.mbt", "y >= 18446744073709551616.0", "y > 18446744073709551616.0"),
    ("signaling payload accepts zero (encodes infinity)", F + "bits.mbt", "payload == 0UL || payload >", "payload >"),
    ("negate_bits sets instead of toggling the sign", F + "bits.mbt", "bits ^ 0x8000000000000000UL", "bits | 0x8000000000000000UL"),
    ("binary32 signaling payload accepts zero", B + "bits.mbt", "payload == 0U || payload >", "payload >"),
    ("signaling predicates ignore quiet NaN operands", F + "comparison.mbt", "(predicate_is_signaling(predicate) && nan_operand)", "(predicate_is_signaling(predicate) && signaling_nan_operand)"),
    ("quiet predicates ignore a signaling NaN operand", F + "comparison.mbt", "signaling_nan_operand || (predicate_is_signaling", "(predicate_is_signaling"),
    ("-0 compares unequal to +0", F + "comparison.mbt", "is_zero_bits(x) && is_zero_bits(y)", "is_zero_bits(x) && is_zero_bits(x)"),
    ("isNormal accepts infinities", F + "bits.mbt", "e != 0UL && e != 0x7ff0000000000000UL", "e != 0UL"),
    ("binary32 isInfinite misses negative infinity", B + "bits.mbt", "(bits & 0x7fffffffU) == 0x7f800000U", "bits == 0x7f800000U"),
    ("binary32 relation treats NaN as equal", B + "comparison.mbt", "@binary64.Unordered\n  } else if", "@binary64.Equal\n  } else if"),
    ("binary32 copy_sign keeps the donor magnitude bit", B + "bits.mbt", "(magnitude & 0x7fffffffU) |", "(magnitude & 0x7ffffffeU) |"),
]


def run(backend):
    result = subprocess.run(["moon", "test", "--target", backend, "-p", "Luna-Flow/luna-utils/ci_probe"],
                            cwd=ROOT, text=True, capture_output=True)
    out = result.stdout + result.stderr
    m = re.search(r"LUNA_AUDIT_VERDICT mismatches=(\d+)", out)
    mism = int(m.group(1)) if m else None
    return result.returncode, mism


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--backend", default="js")
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--count", type=int, default=600)
    parser.add_argument("--json")
    args = parser.parse_args()
    subprocess.run([sys.executable, "tools/random_audit.py", "--seed", str(args.seed), "--count", str(args.count), "--write"], cwd=ROOT, check=True)
    code, mism = run(args.backend)
    if code != 0 or mism != 0:
        raise SystemExit(f"unmutated tree does not pass (exit {code}, mismatches {mism})")
    results = []
    for name, rel, old, new in MUTATIONS:
        path = ROOT / rel
        text = path.read_text()
        if old not in text:
            results.append(dict(mutation=name, status="STALE"))
            continue
        path.write_text(text.replace(old, new, 1))
        try:
            code, mism = run(args.backend)
        finally:
            path.write_text(text)
        status = "caught" if mism else ("caught-by-suite" if code else "SURVIVED")
        results.append(dict(mutation=name, status=status, audit_mismatches=mism))
        print(f"{status:16} {name}", flush=True)
    if args.json:
        Path(args.json).write_text(json.dumps(results, indent=1))
    return 1 if any(r["status"] in ("SURVIVED", "STALE") for r in results) else 0


if __name__ == "__main__":
    sys.exit(main())
