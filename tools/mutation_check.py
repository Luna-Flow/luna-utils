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
    ("minimumNumber returns the NaN instead of the number", F + "ordering.mbt", "  } else if y != y {\n    x\n  } else {\n    minimum(x, y)", "  } else if y != y {\n    y\n  } else {\n    minimum(x, y)"),
    ("maximumMagnitude picks the smaller magnitude", F + "ordering.mbt", "    if ax > ay {\n      x\n    } else if ay > ax {\n      y\n    } else {\n      maximum(x, y)", "    if ax < ay {\n      x\n    } else if ay < ax {\n      y\n    } else {\n      maximum(x, y)"),
    ("minimumMagnitude breaks ties by maximum", B + "ordering.mbt", "    } else {\n      minimum(x, y)\n    }\n  } else {\n    minimum(x, y)\n  }\n}\n\n///|\n/// IEEE 754-2019 §9.6 maximumMagnitude:", "    } else {\n      maximum(x, y)\n    }\n  } else {\n    minimum(x, y)\n  }\n}\n\n///|\n/// IEEE 754-2019 §9.6 maximumMagnitude:"),
    ("totalOrderMag ignores the magnitude", F + "ordering.mbt", "total_order_bits(abs_bits(x), abs_bits(y))", "total_order_bits(x, y)"),
    ("remainder rounds the half case to odd", F + "operations.mbt", "twice > divisor || (twice == divisor && q_odd)", "twice > divisor || (twice == divisor && !q_odd)"),
    ("nextUp of zero is zero", F + "operations.mbt", "    1UL\n  } else if bits ==", "    0UL\n  } else if bits =="),
    ("scaleB ties-to-even ignores the odd neighbour", F + "operations.mbt", "cmp > 0 || (cmp == 0 && (kept & 1UL) == 1UL)", "cmp > 0 || cmp == 0"),
    ("logB of a subnormal is off by one", F + "operations.mbt", "Some((63 - f.clz()) + (-1074))", "Some((63 - f.clz()) + (-1073))"),
    ("binary32 scaleB overflow always gives infinity", B + "operations.mbt", "TowardZero => max_finite", "TowardZero => inf"),
    ("narrowing ties-to-even ignores the odd neighbour", F + "convert_format.mbt", "cmp > 0 || (cmp == 0 && (kept & 1UL) == 1UL)", "cmp > 0 || cmp == 0"),
    ("narrowing loses the carry into the next binade", F + "convert_format.mbt", "if sig == 0x1000000UL {", "if sig == 0x1000001UL {"),
    ("widening a binary32 subnormal is off by one binade", B + "convert_format.mbt", "let t = -126 - (shift - 29)", "let t = -125 - (shift - 29)"),
    ("fma sticky bit is dropped", F + "fma.mbt", "      { hi: r.hi, lo: r.lo | 1UL }", "      r"),
    ("fma exact cancellation gives -0 for every direction", F + "fma.mbt", "zero_bits_for(direction == TowardNegative, mbits)\n        } else if c > 0", "zero_bits_for(true, mbits)\n        } else if c > 0"),
    ("fma 64x64 product loses a carry", F + "fma.mbt", "p11 + (p01 >> 32) + (p10 >> 32) + (mid >> 32)", "p11 + (p01 >> 32) + (p10 >> 32)"),
    ("fma ties-to-even picks the odd neighbour", F + "fma.mbt", "cmp == 0 && inexact && (kept & 1UL) == 1UL", "cmp == 0 && inexact && (kept & 1UL) == 0UL"),
    ("fma overflow threshold is off by one binade", F + "fma.mbt", "if field >= exp_field_max {", "if field > exp_field_max {"),
    ("binary32 fma NaN operand is not quieted", B + "fma.mbt", "  if is_nan_bits(x) {\n    x | 0x400000U", "  if is_nan_bits(x) {\n    x"),
    ("two_sum drops the second correction term", F + "error_free.mbt", "(a - (s - bb)) + (b - bb)", "(a - (s - bb))"),
    ("two_prod error has the wrong sign", F + "error_free.mbt", "(p, fma(a, b, -p))", "(p, fma(a, b, p))"),
    ("binary32 fast_two_sum error is not normalized to +0", B + "error_free.mbt", "if b - (s - a) == 0.0F { 0.0F } else { b - (s - a) }", "b - (s - a)"),
    ("underflow is raised for exact subnormal results", F + "fma.mbt", "underflow: tiny && inexact", "underflow: tiny"),
    ("tininess is detected before rounding", F + "fma.mbt", "tiny = !(carried && t + 1 >= emin)", "tiny = true"),
    ("overflow does not raise inexact", F + "fma.mbt", "{ ..Flags::none(), overflow: true, inexact: true }", "{ ..Flags::none(), overflow: true }"),
    ("remainder by zero is not invalid", F + "flagged.mbt", "(is_infinite_bits(x) || is_zero_bits(y))", "(is_infinite_bits(x))"),
    ("logB of zero does not raise divideByZero", F + "flagged.mbt", "divide_by_zero: true", "divide_by_zero: false"),
    ("non-exact conversion raises inexact", F + "flagged.mbt", "inexact: exact && rounded(x, direction) != x })\n  }\n}\n\n///|\n/// convertToInteger to `Int64`", "inexact: rounded(x, direction) != x })\n  }\n}\n\n///|\n/// convertToInteger to `Int64`"),
    ("roundToIntegral without exact raises inexact", F + "flagged.mbt", "inexact: exact && r != bits", "inexact: r != bits"),
    ("fma signaling NaN is not invalid", F + "fma.mbt", "let invalid_nan = is_signaling_bits(x) ||\n    is_signaling_bits(y) ||\n    is_signaling_bits(z)", "let invalid_nan = false"),
    ("binary32 widening of a signaling NaN is not invalid", B + "flagged.mbt", "invalid: is_signaling_bits(bits) },\n  )\n}\n\n///|\n/// nextUp", "invalid: false },\n  )\n}\n\n///|\n/// nextUp"),
    ("signaling predicates ignore quiet NaN operands", F + "comparison.mbt", "(predicate_is_signaling(predicate) && nan_operand)", "(predicate_is_signaling(predicate) && signaling_nan_operand)"),
    ("quiet predicates ignore a signaling NaN operand", F + "comparison.mbt", "signaling_nan_operand || (predicate_is_signaling", "(predicate_is_signaling"),
    ("-0 compares unequal to +0", F + "comparison.mbt", "is_zero_bits(x) && is_zero_bits(y)", "is_zero_bits(x) && is_zero_bits(x)"),
    ("isNormal accepts infinities", F + "bits.mbt", "e != 0UL && e != 0x7ff0000000000000UL", "e != 0UL"),
    ("binary32 isInfinite misses negative infinity", B + "bits.mbt", "(bits & 0x7fffffffU) == 0x7f800000U", "bits == 0x7f800000U"),
    ("binary32 relation treats NaN as equal", B + "comparison.mbt", "@binary64.Unordered\n  } else if", "@binary64.Equal\n  } else if"),
    ("binary32 copy_sign keeps the donor magnitude bit", B + "bits.mbt", "(magnitude & 0x7fffffffU) |", "(magnitude & 0x7ffffffeU) |"),
]


def run(backend):
    """Run the audit once; return (failed tests other than the audit verdict, unexpected mismatches)."""
    sys.path.insert(0, str(ROOT / "tools"))
    from random_audit import report
    result = subprocess.run(["moon", "test", "--target", backend, "-p", "Luna-Flow/luna-utils/ci_probe"],
                            cwd=ROOT, text=True, capture_output=True)
    out = result.stdout + result.stderr
    summary = report(out)
    known_path = ROOT / "tools/known_issues.json"
    known = {e["family"] for e in (json.loads(known_path.read_text()) if known_path.exists() else [])
             if "family" in e and e["backend"] == backend and e["mode"] == "debug"}
    known_mismatches = sum(v["mismatches"] for f, v in summary["families"].items() if f in known)
    unexpected = summary["mismatch_count"] - known_mismatches
    totals = re.search(r"Total tests: \d+, passed: \d+, failed: (\d+)", out)
    failed = int(totals.group(3 - 2)) if totals else 1
    other_failures = failed - (1 if summary["mismatch_count"] else 0)
    if not summary["families"]:
        return 1, None
    return other_failures, unexpected


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
        raise SystemExit(f"unmutated tree does not pass (other failures {code}, unexpected mismatches {mism})")
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
