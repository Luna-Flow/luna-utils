#!/usr/bin/env python3
"""Self-test of the exact models used by tools/random_audit.py.

The audit trusts these models, so they are checked against CPython's own
IEEE conversions (binary64 exactly, binary32 through struct) before every run.
"""
import random
import struct
import sys
from fractions import Fraction
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from random_audit import Fmt, round_fraction, key, m_extremum, m_round_to_integral  # noqa: E402


def main():
    rng = random.Random(5)
    f64, f32 = Fmt(64), Fmt(32)
    for _ in range(5000):
        bits = rng.getrandbits(64)
        x = struct.unpack(">d", struct.pack(">Q", bits))[0]
        if x != x or x in (float("inf"), float("-inf")):
            continue
        assert f64.value(bits) == Fraction(x), hex(bits)
        assert f64.encode_nearest_even(Fraction(x)) == bits or x == 0, hex(bits)
        b32 = rng.getrandbits(32)
        y = struct.unpack(">f", struct.pack(">I", b32))[0]
        if y != y or y in (float("inf"), float("-inf")):
            continue
        assert f32.value(b32) == Fraction(y), hex(b32)
        assert f32.encode_nearest_even(Fraction(y)) == b32 or y == 0
        # halfway between two binary32 neighbours rounds to even; CPython rounds a double the same way
        z = rng.uniform(-1e6, 1e6)
        assert f32.encode_nearest_even(Fraction(z)) == struct.unpack(">I", struct.pack(">f", z))[0]
    table = [(Fraction(5, 2), "TiesToEven", 2), (Fraction(5, 2), "TiesToAway", 3), (Fraction(-5, 2), "TiesToAway", -3),
             (Fraction(-5, 2), "TiesToEven", -2), (Fraction(-1, 2), "TowardNegative", -1), (Fraction(-1, 2), "TowardPositive", 0),
             (Fraction(7, 2), "TiesToEven", 4), (Fraction(-7, 3), "TowardZero", -2), (Fraction(7, 3), "TowardZero", 2)]
    for v, d, want in table:
        assert round_fraction(v, d) == want, (v, d)
    assert m_round_to_integral(f64, f64.sign | 1, "TowardPositive") == f64.sign  # -tiny rounds up to -0
    assert m_round_to_integral(f64, 1, "TowardPositive") == f64.encode_exact(Fraction(1))
    exp = f64.emax_field << 52
    order = [f64.sign | exp | (1 << 51), f64.sign | exp | 1, f64.sign | exp, f64.sign | 1, f64.sign, 0, 1, exp, exp | 1, f64.canonical_nan]
    keys = [key(f64, b) for b in order]
    assert keys == sorted(keys) and len(set(keys)) == len(keys)
    assert m_extremum(f64, f64.sign, 0, True) == f64.sign and m_extremum(f64, f64.sign, 0, False) == 0
    print("audit models: ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
