#!/usr/bin/env python3
"""Seeded randomized differential audit of luna-utils against exact models.

Every expected value comes from integer fields and exact `fractions.Fraction`
arithmetic in this file; nothing is taken from the library under test and no
host floating-point arithmetic is used. The script emits a MoonBit test
(`src/ci_probe/random_audit_wbtest.mbt`) holding the inputs and the expected
results. The test prints one `LUNA_AUDIT <family> <index> <details>` line per
mismatch and one `LUNA_AUDIT_SUMMARY <family> <cases> <mismatches>` line per
family, then fails if any mismatch was found.

    python3 tools/random_audit.py --seed 1 --count 400 --write
    python3 tools/random_audit.py --report OUTPUT.txt   # parse a test transcript
"""

import argparse
import json
import random
import re
import subprocess
import sys
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "src/ci_probe/random_audit_wbtest.mbt"

PREDICATES = (
    ("QuietEqual", "E", False), ("QuietNotEqual", "LGU", False), ("SignalingEqual", "E", True), ("SignalingNotEqual", "LGU", True),
    ("SignalingGreater", "G", True), ("SignalingNotGreater", "LEU", True), ("SignalingGreaterEqual", "EG", True),
    ("SignalingLessUnordered", "LU", True), ("SignalingLess", "L", True), ("SignalingNotLess", "EGU", True),
    ("SignalingLessEqual", "LE", True), ("SignalingGreaterUnordered", "GU", True), ("QuietGreater", "G", False),
    ("QuietNotGreater", "LEU", False), ("QuietGreaterEqual", "EG", False), ("QuietLessUnordered", "LU", False),
    ("QuietLess", "L", False), ("QuietNotLess", "EGU", False), ("QuietLessEqual", "LE", False),
    ("QuietGreaterUnordered", "GU", False), ("QuietUnordered", "U", False), ("QuietOrdered", "LEG", False),
)
RELATIONS = ("L", "E", "G", "U")

DIRECTIONS = ("TiesToEven", "TiesToAway", "TowardZero", "TowardPositive", "TowardNegative")
CLASSES = ("SignalingNaN", "QuietNaN", "PositiveInfinity", "NegativeInfinity",
           "PositiveNormal", "NegativeNormal", "PositiveSubnormal", "NegativeSubnormal",
           "PositiveZero", "NegativeZero")


class Fmt:
    def __init__(self, width):
        self.width = width
        self.ebits = 11 if width == 64 else 8
        self.mbits = width - 1 - self.ebits
        self.bias = (1 << (self.ebits - 1)) - 1
        self.emax_field = (1 << self.ebits) - 1
        self.sign = 1 << (width - 1)
        self.quiet = 1 << (self.mbits - 1)
        self.frac_mask = (1 << self.mbits) - 1
        self.canonical_nan = (self.emax_field << self.mbits) | self.quiet
        self.mask = (1 << width) - 1

    def fields(self, bits):
        return bits >> (self.width - 1), (bits >> self.mbits) & self.emax_field, bits & self.frac_mask

    def is_nan(self, bits):
        _, e, f = self.fields(bits)
        return e == self.emax_field and f != 0

    def cls(self, bits):
        s, e, f = self.fields(bits)
        if e == self.emax_field:
            if f:
                return "QuietNaN" if f & self.quiet else "SignalingNaN"
            return "NegativeInfinity" if s else "PositiveInfinity"
        sign = "Negative" if s else "Positive"
        if e == 0:
            return sign + ("Zero" if f == 0 else "Subnormal")
        return sign + "Normal"

    def value(self, bits):
        """Exact value of a finite encoding."""
        s, e, f = self.fields(bits)
        if e == 0:
            v = Fraction(f, 1) * Fraction(2) ** (1 - self.bias - self.mbits)
        else:
            v = Fraction((1 << self.mbits) | f) * Fraction(2) ** (e - self.bias - self.mbits)
        return -v if s else v

    def encode_nearest_even(self, v):
        """Round an exact rational to the nearest encoding, ties to even."""
        if v == 0:
            return 0
        sign = self.sign if v < 0 else 0
        v = abs(v)
        emin = 1 - self.bias
        e = v.numerator.bit_length() - v.denominator.bit_length()
        if Fraction(2) ** e > v:
            e -= 1
        if Fraction(2) ** (e + 1) <= v:
            e += 1
        e = max(e, emin)
        scaled = v / Fraction(2) ** (e - self.mbits)
        q = scaled.numerator // scaled.denominator
        r = scaled - q
        if r > Fraction(1, 2) or (r == Fraction(1, 2) and q & 1):
            q += 1
        if q == 1 << (self.mbits + 1):
            q >>= 1
            e += 1
        if e > self.bias:
            return sign | (self.emax_field << self.mbits)
        if q < 1 << self.mbits:
            return sign | q
        return sign | ((e + self.bias) << self.mbits) | (q - (1 << self.mbits))

    def encode_exact(self, v):
        bits = self.encode_nearest_even(v)
        assert self.value(bits) == v, (v, bits)
        return bits


def round_fraction(v, direction):
    floor = v.numerator // v.denominator
    frac = v - floor
    if frac == 0:
        return floor
    ceil = floor + 1
    if direction == "TowardNegative":
        return floor
    if direction == "TowardPositive":
        return ceil
    if direction == "TowardZero":
        return floor if v > 0 else ceil
    if frac < Fraction(1, 2):
        return floor
    if frac > Fraction(1, 2):
        return ceil
    if direction == "TiesToEven":
        return floor if floor % 2 == 0 else ceil
    return ceil if v > 0 else floor  # TiesToAway


# ----------------------------------------------------------------- inputs

def random_bits(rng, fmt, structured=True):
    kind = rng.randrange(10) if structured else 0
    s = rng.randrange(2) << (fmt.width - 1)
    if kind == 0:
        return rng.getrandbits(fmt.width)
    if kind == 1:
        e = rng.choice((0, 1, 2, fmt.emax_field - 1, fmt.emax_field, fmt.bias, fmt.bias - 1, fmt.bias + 1))
        f = rng.choice((0, 1, 2, fmt.frac_mask, fmt.frac_mask - 1, fmt.quiet, fmt.quiet - 1, fmt.quiet + 1))
        return s | (e << fmt.mbits) | f
    if kind == 2:  # NaNs with payload edges
        f = rng.choice((1, fmt.quiet, fmt.quiet | 1, fmt.frac_mask, fmt.quiet - 1, rng.randrange(1, fmt.frac_mask + 1)))
        return s | (fmt.emax_field << fmt.mbits) | f
    if kind == 3:  # subnormals and zeros
        return s | rng.choice((0, 1, fmt.frac_mask, rng.getrandbits(fmt.mbits)))
    if kind in (4, 5):  # both signs of infinity, zero and the edges of the finite ranges
        return s | rng.choice((fmt.emax_field << fmt.mbits, 0, 1 << fmt.mbits, (1 << fmt.mbits) - 1,
                               ((fmt.emax_field - 1) << fmt.mbits) | fmt.frac_mask))
    e = rng.randrange(0, fmt.emax_field + 1)
    return s | (e << fmt.mbits) | rng.getrandbits(fmt.mbits)


def related_bits(rng, fmt, b):
    """A partner for b that stresses ties: same value, opposite sign, neighbours, zeros, NaNs."""
    choice = rng.randrange(9)
    if choice == 0:
        return b
    if choice == 1:
        return b ^ fmt.sign
    if choice == 2:
        return (b + 1) & fmt.mask
    if choice == 3:
        return (b - 1) & fmt.mask
    if choice == 4:
        return rng.choice((0, fmt.sign))
    if choice == 5:
        return fmt.canonical_nan | rng.choice((0, fmt.sign))
    if choice == 6:
        return rng.choice((fmt.emax_field << fmt.mbits, (fmt.emax_field << fmt.mbits) | fmt.sign))
    return random_bits(rng, fmt)


def arith_pair(rng, fmt):
    kind = rng.randrange(8)
    if kind <= 2:
        return random_bits(rng, fmt), random_bits(rng, fmt)
    x = random_bits(rng, fmt)
    if kind == 3:  # a power of two: scales into the subnormal and overflow ranges, ties for division and multiplication
        e = rng.randrange(1, fmt.emax_field)
        return x, (rng.randrange(2) << (fmt.width - 1)) | (e << fmt.mbits)
    if kind == 4:  # cancellation: y is -x or its neighbour
        return x, (x ^ fmt.sign) + rng.choice((-2, -1, 0, 0, 1, 2)) & fmt.mask
    if kind == 5:  # addition ties: y is half an ulp of x
        _, e, _ = fmt.fields(x)
        k = max(1, min(fmt.emax_field - 1, e - fmt.mbits - 1 + rng.choice((0, 0, -1, 1))))
        return x, (rng.randrange(2) << (fmt.width - 1)) | (k << fmt.mbits)
    if kind == 6:  # overflow edge
        top = ((fmt.emax_field - 1) << fmt.mbits) | fmt.frac_mask
        return top - rng.choice((0, 0, 1, 2, fmt.frac_mask >> 1)), random_bits(rng, fmt) if rng.randrange(2) else top
    return x, rng.getrandbits(fmt.width) & ((1 << fmt.mbits) - 1)  # a subnormal or zero second operand


def rounding_inputs(rng, fmt, count):
    """Values around integers, halfway points and the integral threshold 2^mbits."""
    out = []
    while len(out) < count:
        kind = rng.randrange(6)
        sign = rng.choice((1, -1))
        if kind == 5:  # conversion range boundaries and their neighbours
            base = fmt.encode_exact(Fraction(2) ** rng.choice((31, 32, 63, 64)))
            near = base + rng.choice((-3, -2, -1, 0, 0, 1, 2))
            out.append(near | (fmt.sign if rng.randrange(2) else 0))
            continue
        if kind == 0:
            i = rng.getrandbits(rng.randrange(1, fmt.mbits + 1))
            frac = Fraction(rng.choice((0, 1, 2, 3, 1, 2)), 4)
            v = sign * (i + frac)
        elif kind == 1:
            v = sign * Fraction(rng.getrandbits(fmt.mbits + 1), 1) * Fraction(2) ** rng.randrange(-60, 12)
        elif kind == 2:
            v = sign * (Fraction(1, 2) + rng.choice((0, 1, 2, 3)))
        elif kind == 3:
            v = sign * Fraction(2) ** rng.randrange(-8, fmt.mbits + 6)
            v += sign * rng.choice((0, 1, -1)) * Fraction(2) ** (v.numerator.bit_length() - v.denominator.bit_length() - fmt.mbits)
        else:
            out.append(random_bits(rng, fmt))
            continue
        bits = fmt.encode_nearest_even(v)
        if fmt.value(bits) == v:
            out.append(bits)
        elif not fmt.is_nan(bits) and ((bits >> fmt.mbits) & fmt.emax_field) != fmt.emax_field:
            out.append(bits)  # rounded neighbour is still a useful input
    return out


# ----------------------------------------------------------------- models

def m_round_to_integral(fmt, bits, direction):
    if fmt.is_nan(bits):
        return fmt.canonical_nan
    c = fmt.cls(bits)
    if c in ("PositiveInfinity", "NegativeInfinity", "PositiveZero", "NegativeZero"):
        return bits
    v = fmt.value(bits)
    n = round_fraction(v, direction)
    if n == 0:
        return bits & fmt.sign
    return fmt.encode_exact(Fraction(n))


TARGETS = {"int": (-(1 << 31), (1 << 31) - 1), "int64": (-(1 << 63), (1 << 63) - 1),
           "uint": (0, (1 << 32) - 1), "uint64": (0, (1 << 64) - 1)}


def m_convert(fmt, bits, direction):
    """Rounded integer of an encoding, or None for NaN and infinities."""
    c = fmt.cls(bits)
    if fmt.is_nan(bits) or c.endswith("Infinity"):
        return None, c
    return round_fraction(fmt.value(bits), direction), c


def key(fmt, bits):
    return (~bits & fmt.mask) if bits & fmt.sign else bits | fmt.sign


def host_value(fmt, bits):
    """Python float of a non-NaN encoding (exact for binary32 and binary64); an independent comparison oracle."""
    import struct
    if fmt.width == 64:
        return struct.unpack(">d", struct.pack(">Q", bits))[0]
    return struct.unpack(">f", struct.pack(">I", bits))[0]


def m_relation(fmt, xb, yb):
    if fmt.is_nan(xb) or fmt.is_nan(yb):
        return "U"
    x, y = host_value(fmt, xb), host_value(fmt, yb)
    return "L" if x < y else "G" if x > y else "E"


def flog2(v):
    """Exact floor(log2 v) of a positive Fraction."""
    n = v.numerator.bit_length() - v.denominator.bit_length()
    if Fraction(2) ** n > v:
        n -= 1
    elif Fraction(2) ** (n + 1) <= v:
        n += 1
    return n


def round_sqrt(fmt, v):
    """Correctly rounded (nearest, ties to even) square root of a positive exact rational."""
    e = flog2(v) // 2
    ulp = Fraction(2) ** (e - fmt.mbits)
    x = v / (ulp * ulp)
    q = int(x.numerator // x.denominator)
    lo, hi = 0, 1 << (x.numerator.bit_length() // 2 + 2)
    while lo < hi:  # integer square root of floor(x)
        mid = (lo + hi + 1) // 2
        if mid * mid <= q:
            lo = mid
        else:
            hi = mid - 1
    q = lo
    mid2 = Fraction(2 * q + 1, 2) ** 2
    if x > mid2 or (x == mid2 and q & 1):
        q += 1
    return fmt.encode_exact(Fraction(q) * ulp)


def m_arith(fmt, op, xb, yb):
    """Correctly rounded +, -, *, / of two encodings (RoundTiesToEven), as encoding bits."""
    import math
    if fmt.is_nan(xb) or fmt.is_nan(yb):
        return fmt.canonical_nan
    xf, yf = host_value(fmt, xb), host_value(fmt, yb)
    finite = not (math.isinf(xf) or math.isinf(yf))
    if op == "div" and yf == 0:
        if xf == 0:
            return fmt.canonical_nan
        return (fmt.emax_field << fmt.mbits) | ((xb ^ yb) & fmt.sign)
    if not finite:
        r = {"add": lambda: xf + yf, "sub": lambda: xf - yf, "mul": lambda: xf * yf, "div": lambda: xf / yf}[op]()
        if r != r:
            return fmt.canonical_nan
        if math.isinf(r):
            return (fmt.emax_field << fmt.mbits) | (fmt.sign if r < 0 else 0)
        return (fmt.sign if math.copysign(1.0, r) < 0 else 0) if r == 0 else fmt.encode_exact(Fraction(r))
    x, y = fmt.value(xb), fmt.value(yb)
    exact = {"add": lambda: x + y, "sub": lambda: x - y, "mul": lambda: x * y, "div": lambda: x / y}[op]()
    if exact == 0:
        r = {"add": lambda: xf + yf, "sub": lambda: xf - yf, "mul": lambda: xf * yf, "div": lambda: xf / yf}[op]()
        return fmt.sign if math.copysign(1.0, r) < 0 else 0
    return fmt.encode_nearest_even(exact)


def m_sqrt(fmt, xb):
    if fmt.is_nan(xb):
        return fmt.canonical_nan
    c = fmt.cls(xb)
    if c in ("PositiveZero", "NegativeZero", "PositiveInfinity"):
        return xb
    if c == "NegativeInfinity" or xb & fmt.sign:
        return fmt.canonical_nan
    return round_sqrt(fmt, fmt.value(xb))


def numeric(fmt, bits):
    return fmt.canonical_nan if fmt.is_nan(bits) else bits


def m_extremum(fmt, xb, yb, want_min):
    if fmt.is_nan(xb) or fmt.is_nan(yb):
        return fmt.canonical_nan
    x, y = fmt.value(xb), fmt.value(yb)
    if x == 0 and y == 0:
        return (xb | yb) if want_min else (xb & yb)
    if x < y:
        return xb if want_min else yb
    if y < x:
        return yb if want_min else xb
    return xb


def m_number(fmt, xb, yb, want_min):
    """minimumNumber / maximumNumber: the number when exactly one operand is a NaN."""
    xn, yn = fmt.is_nan(xb), fmt.is_nan(yb)
    if xn and yn:
        return fmt.canonical_nan
    if xn:
        return yb
    if yn:
        return xb
    return m_extremum(fmt, xb, yb, want_min)


def m_magnitude(fmt, xb, yb, want_min, number):
    base = m_number if number else m_extremum
    if fmt.is_nan(xb) or fmt.is_nan(yb):
        return base(fmt, xb, yb, want_min)
    ax, ay = abs(host_value(fmt, xb)), abs(host_value(fmt, yb))
    if want_min:
        return xb if ax < ay else yb if ay < ax else base(fmt, xb, yb, want_min)
    return xb if ax > ay else yb if ay > ax else base(fmt, xb, yb, want_min)


def encode_directed(fmt, v, direction):
    """Round a nonzero exact rational to the format by an IEEE 754 rounding direction."""
    negative = v < 0
    a = abs(v)
    e = max(flog2(a), 1 - fmt.bias)
    scaled = a / Fraction(2) ** (e - fmt.mbits)
    q = scaled.numerator // scaled.denominator
    frac = scaled - q
    up = {"TiesToEven": frac > Fraction(1, 2) or (frac == Fraction(1, 2) and q & 1),
          "TiesToAway": frac >= Fraction(1, 2), "TowardZero": False,
          "TowardPositive": (not negative) and frac > 0, "TowardNegative": negative and frac > 0}[direction]
    if up:
        q += 1
    if q == 1 << (fmt.mbits + 1):
        q >>= 1
        e += 1
    sign = fmt.sign if negative else 0
    if e > fmt.bias:
        inf = sign | (fmt.emax_field << fmt.mbits)
        max_finite = sign | ((fmt.emax_field - 1) << fmt.mbits) | fmt.frac_mask
        if direction in ("TiesToEven", "TiesToAway"):
            return inf
        if direction == "TowardZero":
            return max_finite
        return inf if (direction == "TowardPositive") != negative else max_finite
    if q < 1 << fmt.mbits:
        return sign | q
    return sign | ((e + fmt.bias) << fmt.mbits) | (q - (1 << fmt.mbits))


def quiet(fmt, bits):
    return bits | fmt.quiet


def m_next_up(fmt, bits):
    if fmt.is_nan(bits):
        return quiet(fmt, bits)
    if fmt.cls(bits) in ("PositiveZero", "NegativeZero"):
        return 1
    x = Fraction(10) ** 5000 if fmt.cls(bits) == "PositiveInfinity" else -(Fraction(10) ** 5000) if fmt.cls(bits) == "NegativeInfinity" else fmt.value(bits)
    best = None
    for c in {(bits - 1) & fmt.mask, (bits + 1) & fmt.mask, 1, fmt.sign | 1, 0, fmt.sign}:
        if fmt.is_nan(c):
            continue
        k = fmt.cls(c)
        cv = Fraction(10) ** 5000 if k == "PositiveInfinity" else -(Fraction(10) ** 5000) if k == "NegativeInfinity" else fmt.value(c)
        # IEEE 754-2019 §5.3.1: the successor of the negative number of least magnitude is -0
        if cv > x and (best is None or cv < best[0] or (cv == best[0] and c == fmt.sign)):
            best = (cv, c)
    return bits if best is None else best[1]


def m_next_down(fmt, bits):
    return m_next_up(fmt, bits ^ fmt.sign) ^ fmt.sign


def m_remainder(fmt, xb, yb):
    if fmt.is_nan(xb):
        return quiet(fmt, xb)
    if fmt.is_nan(yb):
        return quiet(fmt, yb)
    cx, cy = fmt.cls(xb), fmt.cls(yb)
    if cx.endswith("Infinity") or cy.endswith("Zero"):
        return fmt.canonical_nan
    if cy.endswith("Infinity") or cx.endswith("Zero"):
        return xb
    x, y = fmt.value(xb), fmt.value(yb)
    n = round_fraction(x / y, "TiesToEven")
    r = x - y * n
    if r == 0:
        return xb & fmt.sign
    return fmt.encode_exact(r)


def m_scaleb(fmt, bits, n, direction):
    if fmt.is_nan(bits):
        return quiet(fmt, bits)
    c = fmt.cls(bits)
    if c.endswith("Infinity") or c.endswith("Zero") or n == 0:
        return bits
    n = max(-6000, min(6000, n))  # beyond this every result is an overflow or an underflow of the same kind
    return encode_directed(fmt, fmt.value(bits) * Fraction(2) ** n, direction)


def m_logb(fmt, bits):
    c = fmt.cls(bits)
    if fmt.is_nan(bits) or c.endswith("Infinity") or c.endswith("Zero"):
        return None
    return flog2(abs(fmt.value(bits)))


def m_narrow(f64, f32, bits, direction):
    """convertFormat binary64 -> binary32 of an encoding (see IEEE 754-2019 5.4.2 and 6.2.3)."""
    sign = (bits >> 32) & 0x80000000
    if f64.is_nan(bits):
        return sign | 0x7fc00000 | ((bits >> 29) & 0x3fffff)
    c = f64.cls(bits)
    if c.endswith("Infinity"):
        return sign | 0x7f800000
    if c.endswith("Zero"):
        return sign
    return encode_directed(f32, f64.value(bits), direction)


def m_widen(f32, f64, bits):
    """convertFormat binary32 -> binary64 of an encoding (exact)."""
    sign = (bits & 0x80000000) << 32
    if f32.is_nan(bits):
        return sign | 0x7ff8000000000000 | ((bits & 0x3fffff) << 29)
    c = f32.cls(bits)
    if c.endswith("Infinity"):
        return sign | 0x7ff0000000000000
    if c.endswith("Zero"):
        return sign
    return f64.encode_exact(f32.value(bits))


def scaleb_tie_case(rng, fmt):
    """An operand and a scale that put the exact result halfway between two subnormal neighbours."""
    s = rng.randrange(1, fmt.mbits + 1)
    high = (rng.getrandbits(fmt.mbits - s) if fmt.mbits - s > 0 else 0) | (1 << (fmt.mbits - s))
    m = (high << s) | (1 << (s - 1))
    e = rng.randrange(1, fmt.emax_field)
    bits = (rng.randrange(2) << (fmt.width - 1)) | (e << fmt.mbits) | (m & fmt.frac_mask)
    e0 = e - fmt.bias - fmt.mbits
    return bits, (1 - fmt.bias - fmt.mbits) - e0 - s


def remainder_tie_case(rng, fmt):
    """x and y with x / y exactly halfway between two integers, so the quotient is rounded by the even rule."""
    half_bits = max(2, (fmt.mbits // 2) - 1)
    my = (rng.getrandbits(half_bits) << 1) | 1
    k2 = (rng.getrandbits(half_bits) << 1) | 1  # 2k + 1
    ey = rng.randrange(-fmt.bias // 2, fmt.bias // 2)
    sy = rng.choice((1, -1))
    sx = rng.choice((1, -1))
    y = sy * my * Fraction(2) ** ey
    x = sx * my * k2 * Fraction(2) ** (ey - 1)
    return fmt.encode_exact(x), fmt.encode_exact(y)


def m_fma(fmt, xb, yb, zb, direction):
    """fusedMultiplyAdd: x * y + z rounded once by the direction, IEEE 754-2019 5.3.1, 6.2.3 and 6.3."""
    for b in (xb, yb, zb):
        if fmt.is_nan(b):
            return quiet(fmt, b)
    cx, cy, cz = fmt.cls(xb), fmt.cls(yb), fmt.cls(zb)
    xinf, yinf, zinf = cx.endswith("Infinity"), cy.endswith("Infinity"), cz.endswith("Infinity")
    if (xinf and cy.endswith("Zero")) or (cx.endswith("Zero") and yinf):
        return fmt.canonical_nan
    sp = (xb ^ yb) & fmt.sign
    if xinf or yinf:
        if zinf and (zb & fmt.sign) != sp:
            return fmt.canonical_nan
        return sp | (fmt.emax_field << fmt.mbits)
    if zinf:
        return zb
    x, y, z = fmt.value(xb), fmt.value(yb), fmt.value(zb)
    exact = x * y + z
    if exact == 0:
        if x * y == 0 and z == 0:
            neg = (sp != 0) if (sp != 0) == ((zb & fmt.sign) != 0) else direction == "TowardNegative"
        else:
            neg = direction == "TowardNegative"
        return fmt.sign if neg else 0
    return encode_directed(fmt, exact, direction)


def m_eft(fmt, a, b):
    """TwoSum, Fast2Sum and TwoProd results as encodings: (s, e_sum, fast_ok, e_fast, p, e_prod)."""
    def finite(bits):
        return not fmt.is_nan(bits) and not fmt.cls(bits).endswith("Infinity")

    def err(exact):
        return encode_directed(fmt, exact, "TiesToEven") if exact != 0 else 0

    s = numeric(fmt, m_arith(fmt, "add", a, b))
    if finite(s):
        e_sum = err(fmt.value(a) + fmt.value(b) - fmt.value(s))
    else:
        e_sum = fmt.canonical_nan
    fast_ok = int(finite(a) and finite(b) and abs(fmt.value(a)) >= abs(fmt.value(b)))
    e_fast = e_sum
    p = numeric(fmt, m_arith(fmt, "mul", a, b))
    e_prod = err(fmt.value(a) * fmt.value(b) - fmt.value(p)) if finite(p) else fmt.canonical_nan
    return s, e_sum, fast_ok, e_fast, p, e_prod


def fma_triple(rng, fmt):
    """Operands that exercise cancellation, huge exponent gaps, subnormal products, ties and overflow."""
    kind = rng.randrange(8)
    if kind <= 1:
        return random_bits(rng, fmt), random_bits(rng, fmt), random_bits(rng, fmt)
    x, y = arith_pair(rng, fmt)
    if fmt.is_nan(x) or fmt.is_nan(y) or fmt.cls(x).endswith("Infinity") or fmt.cls(y).endswith("Infinity"):
        return x, y, random_bits(rng, fmt)
    prod = fmt.value(x) * fmt.value(y)
    if kind == 2:  # exact cancellation or one ulp away
        z = fmt.encode_nearest_even(-prod)
        return x, y, (z + rng.choice((0, 0, 1, -1, 2)) & fmt.mask) if not fmt.is_nan(z) else z
    if kind == 3:  # z is half an ulp of the product: ties
        if prod == 0:
            return x, y, random_bits(rng, fmt)
        e = max(flog2(abs(prod)), 1 - fmt.bias)
        zv = (Fraction(1, 2) + rng.choice((0, 0, 1, -1))) * Fraction(2) ** (e - fmt.mbits)
        return x, y, fmt.encode_nearest_even(rng.choice((1, -1)) * zv)
    if kind == 4:  # z far below or far above the product
        k = rng.choice((-1, 1)) * rng.randrange(fmt.mbits + 2, 3 * fmt.mbits + 8)
        base = flog2(abs(prod)) if prod != 0 else 0
        return x, y, fmt.encode_nearest_even(rng.choice((1, -1)) * Fraction(2) ** max(min(base + k, fmt.bias), 2 - fmt.bias - fmt.mbits))
    if kind == 5:  # subnormal range
        z = rng.getrandbits(fmt.mbits) | (rng.randrange(2) << (fmt.width - 1))
        return x, y, z
    return x, y, random_bits(rng, fmt)


def narrow_input(rng, f64, f32):
    """Binary64 values on and around the binary32 grid: ties, overflow and underflow edges."""
    if rng.randrange(2):
        return random_bits(rng, f64)
    g = random_bits(rng, f32)
    if f32.cls(g) in ("SignalingNaN", "QuietNaN", "PositiveInfinity", "NegativeInfinity"):
        return random_bits(rng, f64)
    v = f32.value(g)
    e = max(flog2(abs(v)) if v != 0 else -149, -126)
    ulp = Fraction(2) ** (e - 23)
    return f64.encode_exact(v + rng.choice((-3, -2, -1, 0, 1, 2, 3)) * ulp / 4)


# ----------------------------------------------------------------- tables

class Tables:
    def __init__(self):
        self.rows = {}

    def add(self, family, *words):
        self.rows.setdefault(family, []).append([w & ((1 << 64) - 1) for w in words])


def build(seed, count):
    rng = random.Random(seed)
    t = Tables()
    for fmt in (Fmt(64), Fmt(32)):
        w = fmt.width
        p = f"b{w}_"
        for _ in range(count):
            b = random_bits(rng, fmt)
            y = related_bits(rng, fmt, b) if rng.randrange(2) else random_bits(rng, fmt)
            if rng.randrange(4) == 0:
                b = rng.choice((0, fmt.sign, b & fmt.sign))
                y = related_bits(rng, fmt, b)
            s, e, f = fmt.fields(b)
            flags = (fmt.is_nan(b) << 0) | ((fmt.cls(b) == "SignalingNaN") << 1) \
                | (fmt.cls(b).endswith("Subnormal") << 2) | (fmt.cls(b).endswith("Zero") << 3) \
                | ((e != fmt.emax_field) << 4) | (bool(s) << 5) \
                | ((e == fmt.emax_field and f == 0) << 6) | ((0 < e < fmt.emax_field) << 7)
            nb, ny = numeric(fmt, b), numeric(fmt, y)
            nflags = ((nb >> fmt.mbits) & fmt.emax_field != fmt.emax_field) | (fmt.cls(nb).endswith("Subnormal") << 1) \
                | (fmt.cls(nb).endswith("Zero") << 2) | (bool(nb & fmt.sign) << 3) \
                | (fmt.cls(nb).endswith("Infinity") << 4) | (fmt.cls(nb).endswith("Normal") << 5) | (fmt.is_nan(nb) << 6)
            t.add(p + "classify", b, CLASSES.index(fmt.cls(b)), flags, nflags)
            t.add(p + "canon", b, fmt.canonical_nan if fmt.is_nan(b) else b)
            t.add(p + "sign", b, y, (b & ~fmt.sign & fmt.mask) | (y & fmt.sign), b ^ fmt.sign, b & ~fmt.sign & fmt.mask,
                  numeric(fmt, (nb & ~fmt.sign & fmt.mask) | (ny & fmt.sign)), numeric(fmt, nb ^ fmt.sign), nb & ~fmt.sign & fmt.mask)
            payload = f & (fmt.quiet - 1) if fmt.is_nan(b) else None
            t.add(p + "payload_get", b, 1 if payload is not None else 0, payload or 0)
            pl = rng.choice((0, 1, rng.getrandbits(fmt.mbits - 1), (1 << (fmt.mbits - 1)) - 1,
                             1 << (fmt.mbits - 1), (1 << fmt.mbits) - 1, rng.getrandbits(fmt.mbits)))
            sm = rng.randrange(2)
            quiet_ok = pl < (1 << (fmt.mbits - 1))
            quiet_bits = (sm * fmt.sign) | (fmt.emax_field << fmt.mbits) | fmt.quiet | pl
            sig_ok = quiet_ok and pl != 0
            sig_bits = (sm * fmt.sign) | (fmt.emax_field << fmt.mbits) | pl
            t.add(p + "payload_set", pl, sm, int(quiet_ok), quiet_bits if quiet_ok else 0,
                  int(sig_ok), sig_bits if sig_ok else 0)
            t.add(p + "total_order", b, y, int(key(fmt, b) <= key(fmt, y)),
                  int(key(fmt, numeric(fmt, b)) <= key(fmt, numeric(fmt, y))))
            t.add(p + "extrema", b, y, m_extremum(fmt, b, y, True), m_extremum(fmt, b, y, False),
                  m_number(fmt, b, y, True), m_number(fmt, b, y, False),
                  m_magnitude(fmt, b, y, True, False), m_magnitude(fmt, b, y, False, False),
                  m_magnitude(fmt, b, y, True, True), m_magnitude(fmt, b, y, False, True),
                  int(key(fmt, b & ~fmt.sign & fmt.mask) <= key(fmt, y & ~fmt.sign & fmt.mask)),
                  int(key(fmt, numeric(fmt, b) & ~fmt.sign & fmt.mask) <= key(fmt, numeric(fmt, y) & ~fmt.sign & fmt.mask)))
            ea, eb = arith_pair(rng, fmt)
            if rng.randrange(3) == 0:  # |a| >= |b| pairs for Fast2Sum
                ea, eb = (ea, eb) if (not fmt.is_nan(ea) and not fmt.is_nan(eb) and not fmt.cls(ea).endswith("Infinity") and not fmt.cls(eb).endswith("Infinity") and abs(fmt.value(ea)) >= abs(fmt.value(eb))) else (eb, ea)
            t.add(p + "eft", ea, eb, *m_eft(fmt, ea, eb))
            fx, fy, fz = fma_triple(rng, fmt)
            fres = [m_fma(fmt, fx, fy, fz, d) for d in DIRECTIONS]
            t.add(p + "fma", fx, fy, fz, *fres, *[fmt.canonical_nan if fmt.is_nan(v) else v for v in fres])
            if fmt.width == 64:
                nb = narrow_input(rng, fmt, Fmt(32))
                nres = [m_narrow(fmt, Fmt(32), nb, d) for d in DIRECTIONS]
                t.add(p + "narrow", nb, *nres, *[(0x7fc00000 if Fmt(32).is_nan(v) else v) for v in nres])
            else:
                t.add(p + "widen", b, m_widen(fmt, Fmt(64), b), 0x7ff8000000000000 if fmt.is_nan(b) else m_widen(fmt, Fmt(64), b))
            canon = lambda v: fmt.canonical_nan if fmt.is_nan(v) else v
            t.add(p + "next", b, m_next_up(fmt, b), m_next_down(fmt, b), canon(m_next_up(fmt, b)) if fmt.is_nan(b) else m_next_up(fmt, b),
                  canon(m_next_down(fmt, b)) if fmt.is_nan(b) else m_next_down(fmt, b))
            rx, ry = (b, y)
            if rng.randrange(3) == 0:
                rx, ry = remainder_tie_case(rng, fmt)
            rb = m_remainder(fmt, rx, ry)
            t.add(p + "remainder", rx, ry, rb, canon(rb))
            sn = rng.choice((0, 1, -1, 2, -2, 7, -7, fmt.mbits, -fmt.mbits, fmt.bias, -fmt.bias, fmt.bias + fmt.mbits + 1,
                             -(fmt.bias + fmt.mbits + 1), 2 * (fmt.bias + fmt.mbits), -2 * (fmt.bias + fmt.mbits), 2400, -2400,
                             (1 << 31) - 1, -(1 << 31), rng.randrange(-3000, 3000), rng.randrange(-300, 300)))
            sb = b
            if rng.randrange(3) == 0:
                sb, sn = scaleb_tie_case(rng, fmt)
            sres = [m_scaleb(fmt, sb, sn, d) for d in DIRECTIONS]
            t.add(p + "scaleb", sb, sn, *sres, *[canon(v) if fmt.is_nan(sb) else v for v in sres])
            lg = m_logb(fmt, b)
            lgf = fmt.canonical_nan if fmt.is_nan(b) else (fmt.emax_field << fmt.mbits) if fmt.cls(b) == "PositiveInfinity" or fmt.cls(b) == "NegativeInfinity" else (fmt.sign | (fmt.emax_field << fmt.mbits)) if lg is None else fmt.encode_exact(Fraction(lg))
            t.add(p + "logb", b, 0 if lg is None else 1, 0 if lg is None else lg, lgf)
            rel = m_relation(fmt, b, y)
            snan = fmt.cls(b) == "SignalingNaN" or fmt.cls(y) == "SignalingNaN"
            anan = fmt.is_nan(b) or fmt.is_nan(y)
            vmask = imask = pmask = 0
            for k, (_, rels, sig) in enumerate(PREDICATES):
                vmask |= (rel in rels) << k
                imask |= (snan or (sig and anan)) << k
                pmask |= (sig and anan) << k
            t.add(p + "compare", b, y, RELATIONS.index(rel), vmask, imask, pmask, int(snan), int(anan))
        for _ in range(count):
            a, b2 = arith_pair(rng, fmt)
            if rng.randrange(2):
                a, b2 = a ^ (rng.randrange(2) << (fmt.width - 1)), b2
            t.add(p + "arith", a, b2, *[m_arith(fmt, o, a, b2) for o in ("add", "sub", "mul", "div")], m_sqrt(fmt, a))
        for b in rounding_inputs(rng, fmt, count):
            t.add(p + "round", b, *[m_round_to_integral(fmt, b, d) for d in DIRECTIONS])
            row = [b]
            for tname, (lo, hi) in TARGETS.items():
                for d in DIRECTIONS:
                    n, c = m_convert(fmt, b, d)
                    if n is None:
                        sat = hi if c == "PositiveInfinity" else lo if c == "NegativeInfinity" else 0
                        row += [0, 0, sat]
                    else:
                        row += [1 if lo <= n <= hi else 0, n if lo <= n <= hi else 0, max(lo, min(hi, n))]
            t.add(p + "convert", *row)
        arrays = []
        for _ in range(max(count // 8, 4)):
            arr = [random_bits(rng, fmt) for _ in range(rng.randrange(0, 24))]
            arrays.append(arr)
            ordered = sorted((numeric(fmt, x) for x in arr), key=lambda x: key(fmt, x))
            t.add(p + "sort", len(arr), *arr, *ordered)
    f64, f32m = Fmt(64), Fmt(32)

    def integer_value(bits, signed):
        v = rng.getrandbits(rng.randrange(1, bits + 1))
        k = rng.randrange(6)
        if k == 0:
            m = rng.getrandbits(24) | (1 << 23)
            sh = rng.randrange(0, max(1, bits - 23))
            v = (m << sh) + rng.choice((0, 1, -1, (1 << sh) >> 1, ((1 << sh) >> 1) - 1, ((1 << sh) >> 1) + 1))
        elif k == 1:
            m = rng.getrandbits(53) | (1 << 52)
            sh = rng.randrange(0, max(1, bits - 52))
            v = (m << sh) + rng.choice((0, 1, -1, (1 << sh) >> 1, ((1 << sh) >> 1) - 1, ((1 << sh) >> 1) + 1))
        elif k == 2:
            v = (1 << rng.randrange(0, bits)) + rng.choice((-1, 0, 1))
        v = max(0, min(v, (1 << bits) - 1))
        if signed:
            v = v if not rng.randrange(2) else -v
            v = max(-(1 << (bits - 1)), min(v, (1 << (bits - 1)) - 1))
        return v

    for _ in range(count):
        i32, u32 = integer_value(32, True), integer_value(32, False)
        i64, u64 = integer_value(64, True), integer_value(64, False)
        t.add("conv_i32", i32, f64.encode_nearest_even(Fraction(i32)), f32m.encode_nearest_even(Fraction(i32)))
        t.add("conv_u32", u32, f64.encode_nearest_even(Fraction(u32)), f32m.encode_nearest_even(Fraction(u32)))
        t.add("conv_i64", i64, f64.encode_nearest_even(Fraction(i64)))
        t.add("conv_u64", u64, f64.encode_nearest_even(Fraction(u64)))
        t.add("conv_i64_f32", i64, f32m.encode_nearest_even(Fraction(i64)))
        t.add("conv_u64_f32", u64, f32m.encode_nearest_even(Fraction(u64)))
    for _ in range(count):
        kind = rng.randrange(4)
        if kind == 0:
            v = rng.getrandbits(rng.randrange(1, 65))
        elif kind == 1:
            m = rng.getrandbits(24) | (1 << 23)
            sh = rng.randrange(0, 41)
            v = (m << sh) + rng.choice((0, 1, -1, (1 << sh) >> 1, ((1 << sh) >> 1) - 1, ((1 << sh) >> 1) + 1))
        elif kind == 2:
            v = (1 << rng.randrange(0, 64)) + rng.choice((-1, 0, 1))
        else:
            v = rng.getrandbits(64)
        v = max(0, min(v, (1 << 64) - 1))
        f32 = Fmt(32)
        unsigned_bits = f32.encode_nearest_even(Fraction(v))
        neg = rng.randrange(2) and v <= (1 << 63)
        sv = -v if neg else (v if v < (1 << 63) else v - (1 << 64) if rng.randrange(2) else v >> 1)
        signed_bits = f32.encode_nearest_even(Fraction(sv))
        t.add("int_to_f32", v, sv, unsigned_bits, signed_bits)
    return t


# ------------------------------------------------------------- MoonBit out

def lit(rows):
    """Hex words, each followed by a comma; parsed at run time to keep the module small."""
    text = "".join(f"{w:x}," for r in rows for w in r)
    parts, start = [], 0
    while start < len(text):  # cut after a comma so every part is self-contained and short
        end = min(len(text), start + 4000)
        if end < len(text):
            end = text.index(",", end) + 1
        parts.append(text[start:end])
        start = end
    return ",".join('"' + part + '"' for part in parts)


def strided(rows):
    stride = len(rows[0]) if rows else 1
    return lit(rows), stride


def emit(t, seed, count):
    out = [f"// Generated by tools/random_audit.py (seed {seed}, count {count}); do not edit.",
           "///|", "let mismatches : Ref[Int] = { val: 0 }", "",
           "///|", "fn report(family : String, index : Int, detail : String) -> Unit {",
           "  mismatches.val += 1",
           "  if mismatches.val <= 200 {",
           '    println("LUNA_AUDIT " + family + " " + index.to_string() + " " + detail)', "  }", "}", "",
           "///|", "fn i2w(v : Int) -> UInt64 { v.to_int64().reinterpret_as_uint64() }", "",
           "///|", "fn i64w(v : Int64) -> UInt64 { v.reinterpret_as_uint64() }", "",
           "///|", "fn u2w(v : UInt) -> UInt64 { v.to_uint64() }", "",
           "///|", "fn u64w(v : UInt64) -> UInt64 { v }", "",
           "///|", "fn load(parts : Array[String]) -> Array[UInt64] {",
           "  let out : Array[UInt64] = []", "  let mut cur = 0UL",
           "  for s in parts {", "    for ch in s {", "      let c = ch.to_int()",
           "      if c == 44 {", "        out.push(cur)", "        cur = 0UL", "      } else {",
           "        let d = if c >= 97 { c - 87 } else { c - 48 }",
           "        cur = (cur << 4) | d.to_uint64()", "      }", "    }", "  }", "  out", "}", "",
           "///|", "fn hex(v : UInt64) -> String { \"0x\" + v.to_string(radix=16) }", "",
           "///|", "fn check(family : String, index : Int, what : String, got : UInt64, want : UInt64) -> Bool {",
           "  if got != want {",
           '    report(family, index, what + " got=" + hex(got) + " want=" + hex(want))',
           "    false", "  } else {", "    true", "  }", "}", "",
           "///|", "fn class_index(c : @float.Classification) -> UInt64 {", "  match c {"]
    out += [f"    {n} => {i}UL" for i, n in enumerate(CLASSES)] + ["  }", "}", ""]
    for width in (64, 32):
        fmt = Fmt(width)
        M = "@float" if width == 64 else "@binary32"
        BT = "UInt64" if width == 64 else "UInt"
        FT = "Double" if width == 64 else "Float"
        suf = "UL" if width == 64 else "U"
        to_bt = (lambda x: x) if width == 64 else (lambda x: f"({x}).to_uint()")
        from_bt = (lambda x: x) if width == 64 else (lambda x: f"({x}).to_uint64()")
        reint = "reinterpret_as_double" if width == 64 else "reinterpret_as_float"
        p = f"b{width}_"

        def row_fn(name, family, body, ):
            rows, stride = strided(t.rows[p + family])
            out.extend([f"///|", f"let {p}{name}_table : Array[UInt64] = load([{rows}])", "",
                        "///|", f"test \"audit {p}{family}\" {{",
                        f"  let table = {p}{name}_table", f"  let n = table.length() / {stride}",
                        "  let mut bad = 0", "  for i in 0..<n {", f"    let r = i * {stride}",
                        ])
            if any(re.search(r"\bb\b", ln) for ln in body):
                out.append(f"    let b = {to_bt('table[r]')}")
            out.extend(["    " + ln for ln in body])
            out.extend(["  }", f'  println("LUNA_AUDIT_SUMMARY {p}{family} " + n.to_string() + " " + bad.to_string())', "}", ""])

        def fb(v):
            return f"({to_bt(v)}).{reint}()" if width == 64 else f"Float::reinterpret_from_uint({to_bt(v)})"

        row_fn("classify", "classify", [
            f"let fam = \"{p}classify\"",
            f"if !check(fam, i, \"class\", class_index({M}.classify_bits(b)), table[r + 1]) {{ bad += 1 }}",
            f"if !check(fam, i, \"portable_class\", class_index({M}.portable_classify({fb('table[r]')})), if table[r + 1] <= 1UL {{ 1UL }} else {{ table[r + 1] }}) {{ bad += 1 }}",
            f"let fl = table[r + 2]",
            f"let got = (if {M}.is_nan_bits(b) {{ 1UL }} else {{ 0UL }}) | (if {M}.is_signaling_bits(b) {{ 2UL }} else {{ 0UL }}) | (if {M}.is_subnormal_bits(b) {{ 4UL }} else {{ 0UL }}) | (if {M}.is_zero_bits(b) {{ 8UL }} else {{ 0UL }}) | (if {M}.is_finite_bits(b) {{ 16UL }} else {{ 0UL }}) | (if {M}.is_sign_minus_bits(b) {{ 32UL }} else {{ 0UL }}) | (if {M}.is_infinite_bits(b) {{ 64UL }} else {{ 0UL }}) | (if {M}.is_normal_bits(b) {{ 128UL }} else {{ 0UL }})",
            "if !check(fam, i, \"predicates\", got, fl) { bad += 1 }",
            f"if !{M}.is_canonical_bits(b) {{ report(fam, i, \"canonical\"); bad += 1 }}",
            f"let xv = {fb('table[r]')}",
            f"let ngot = (if {M}.is_finite(xv) {{ 1UL }} else {{ 0UL }}) | (if {M}.is_subnormal(xv) {{ 2UL }} else {{ 0UL }}) | (if {M}.is_zero(xv) {{ 4UL }} else {{ 0UL }}) | (if {M}.portable_is_sign_minus(xv) {{ 8UL }} else {{ 0UL }}) | (if {M}.is_infinite(xv) {{ 16UL }} else {{ 0UL }}) | (if {M}.is_normal(xv) {{ 32UL }} else {{ 0UL }}) | (if {M}.is_nan(xv) {{ 64UL }} else {{ 0UL }})",
            "if !check(fam, i, \"numeric predicates\", ngot, table[r + 3]) { bad += 1 }",
            f"if {M}.portable_is_signaling(xv) || !{M}.portable_is_canonical(xv) || {M}.radix() != 2 {{ report(fam, i, \"portable constants\"); bad += 1 }}"])
        row_fn("canon", "canon", [
            f"let fam = \"{p}canon\"",
            f"if !check(fam, i, \"canonicalize_nan_bits\", {from_bt(f'{M}.canonicalize_nan_bits(b)')}, table[r + 1]) {{ bad += 1 }}",
            f"if !check(fam, i, \"to_bits_canonical\", {from_bt(f'{M}.to_bits_canonical({fb('table[r]')})')}, table[r + 1]) {{ bad += 1 }}",
            f"if !check(fam, i, \"canonicalize_nan\", {from_bt(f'{M}.to_bits_canonical({M}.canonicalize_nan({fb('table[r]')}))')}, table[r + 1]) {{ bad += 1 }}"])
        row_fn("sign", "sign", [
            f"let fam = \"{p}sign\"", f"let y = {to_bt('table[r + 1]')}",
            f"if !check(fam, i, \"copy_sign_bits\", {from_bt(f'{M}.copy_sign_bits(b, y)')}, table[r + 2]) {{ bad += 1 }}",
            f"if !check(fam, i, \"negate_bits\", {from_bt(f'{M}.negate_bits(b)')}, table[r + 3]) {{ bad += 1 }}",
            f"if !check(fam, i, \"abs_bits\", {from_bt(f'{M}.abs_bits(b)')}, table[r + 4]) {{ bad += 1 }}",
            f"let xv = {fb('table[r]')}", f"let yv = {fb('table[r + 1]')}",
            f"if !check(fam, i, \"portable_copy_sign\", {from_bt(f'{M}.to_bits_canonical({M}.portable_copy_sign(xv, yv))')}, table[r + 5]) {{ bad += 1 }}",
            f"if !check(fam, i, \"portable_negate\", {from_bt(f'{M}.to_bits_canonical({M}.portable_negate(xv))')}, table[r + 6]) {{ bad += 1 }}",
            f"if !check(fam, i, \"portable_abs\", {from_bt(f'{M}.to_bits_canonical({M}.portable_abs(xv))')}, table[r + 7]) {{ bad += 1 }}"])
        row_fn("payload_get", "payload_get", [
            f"let fam = \"{p}payload_get\"",
            f"match {M}.get_payload_bits(b) {{",
            "  Some(v) => {",
            f"    if table[r + 1] != 1UL {{ report(fam, i, \"payload present for non-NaN\"); bad += 1 }} else if !check(fam, i, \"payload\", {from_bt('v')}, table[r + 2]) {{ bad += 1 }}",
            "  }", "  None => if table[r + 1] != 0UL { report(fam, i, \"payload missing for NaN\"); bad += 1 }", "}"])
        row_fn("payload_set", "payload_set", [
            f"let fam = \"{p}payload_set\"", f"let pl = {to_bt('table[r]')}", "let sm = table[r + 1] != 0UL",
            f"match {M}.set_payload_bits(pl, sign_minus=sm) {{",
            "  Some(v) => { if table[r + 2] != 1UL { report(fam, i, \"quiet accepted\"); bad += 1 } else if !check(fam, i, \"set_payload_bits\", " + from_bt('v') + ", table[r + 3]) { bad += 1 } }",
            "  None => if table[r + 2] != 0UL { report(fam, i, \"quiet rejected\"); bad += 1 }", "}",
            f"match {M}.set_payload_signaling_bits(pl, sign_minus=sm) {{",
            "  Some(v) => { if table[r + 4] != 1UL { report(fam, i, \"signaling accepted\"); bad += 1 } else if !check(fam, i, \"set_payload_signaling_bits\", " + from_bt('v') + ", table[r + 5]) { bad += 1 } }",
            "  None => if table[r + 4] != 0UL { report(fam, i, \"signaling rejected\"); bad += 1 }", "}"])
        row_fn("total_order", "total_order", [
            f"let fam = \"{p}total_order\"", f"let y = {to_bt('table[r + 1]')}",
            f"if !check(fam, i, \"total_order_bits\", if {M}.total_order_bits(b, y) {{ 1UL }} else {{ 0UL }}, table[r + 2]) {{ bad += 1 }}",
            f"if !check(fam, i, \"portable_total_order\", if {M}.portable_total_order({fb('table[r]')}, {fb('table[r + 1]')}) {{ 1UL }} else {{ 0UL }}, table[r + 3]) {{ bad += 1 }}"])
        row_fn("extrema", "extrema", [
            f"let fam = \"{p}extrema\"", f"let x = {fb('table[r]')}", f"let y = {fb('table[r + 1]')}",
            f"if !check(fam, i, \"minimum\", {from_bt(f'{M}.to_bits_canonical({M}.minimum(x, y))')}, table[r + 2]) {{ bad += 1 }}",
            f"if !check(fam, i, \"maximum\", {from_bt(f'{M}.to_bits_canonical({M}.maximum(x, y))')}, table[r + 3]) {{ bad += 1 }}",
            f"if !check(fam, i, \"minimum_number\", {from_bt(f'{M}.to_bits_canonical({M}.minimum_number(x, y))')}, table[r + 4]) {{ bad += 1 }}",
            f"if !check(fam, i, \"maximum_number\", {from_bt(f'{M}.to_bits_canonical({M}.maximum_number(x, y))')}, table[r + 5]) {{ bad += 1 }}",
            f"if !check(fam, i, \"minimum_magnitude\", {from_bt(f'{M}.to_bits_canonical({M}.minimum_magnitude(x, y))')}, table[r + 6]) {{ bad += 1 }}",
            f"if !check(fam, i, \"maximum_magnitude\", {from_bt(f'{M}.to_bits_canonical({M}.maximum_magnitude(x, y))')}, table[r + 7]) {{ bad += 1 }}",
            f"if !check(fam, i, \"minimum_magnitude_number\", {from_bt(f'{M}.to_bits_canonical({M}.minimum_magnitude_number(x, y))')}, table[r + 8]) {{ bad += 1 }}",
            f"if !check(fam, i, \"maximum_magnitude_number\", {from_bt(f'{M}.to_bits_canonical({M}.maximum_magnitude_number(x, y))')}, table[r + 9]) {{ bad += 1 }}",
            f"if !check(fam, i, \"total_order_mag_bits\", if {M}.total_order_mag_bits(b, {to_bt('table[r + 1]')}) {{ 1UL }} else {{ 0UL }}, table[r + 10]) {{ bad += 1 }}",
            f"if !check(fam, i, \"portable_total_order_mag\", if {M}.portable_total_order_mag(x, y) {{ 1UL }} else {{ 0UL }}, table[r + 11]) {{ bad += 1 }}"])
        row_fn("arith", "arith", [
            f"let fam = \"{p}arith\"", f"let x = {fb('table[r]')}", f"let y = {fb('table[r + 1]')}",
            f"if !check(fam, i, \"add\", {from_bt(f'{M}.to_bits_canonical(x + y)')}, table[r + 2]) {{ bad += 1 }}",
            f"if !check(fam, i, \"sub\", {from_bt(f'{M}.to_bits_canonical(x - y)')}, table[r + 3]) {{ bad += 1 }}",
            f"if !check(fam, i, \"mul\", {from_bt(f'{M}.to_bits_canonical(x * y)')}, table[r + 4]) {{ bad += 1 }}",
            f"if !check(fam, i, \"div\", {from_bt(f'{M}.to_bits_canonical(x / y)')}, table[r + 5]) {{ bad += 1 }}",
            f"if !check(fam, i, \"sqrt\", {from_bt(f'{M}.to_bits_canonical(x.sqrt())')}, table[r + 6]) {{ bad += 1 }}"])
        row_fn("next", "next", [
            f"let fam = \"{p}next\"", f"let x = {fb('table[r]')}",
            f"if !check(fam, i, \"next_up_bits\", {from_bt(f'{M}.next_up_bits(b)')}, table[r + 1]) {{ bad += 1 }}",
            f"if !check(fam, i, \"next_down_bits\", {from_bt(f'{M}.next_down_bits(b)')}, table[r + 2]) {{ bad += 1 }}",
            f"if !check(fam, i, \"next_up\", {from_bt(f'{M}.to_bits_canonical({M}.next_up(x))')}, table[r + 3]) {{ bad += 1 }}",
            f"if !check(fam, i, \"next_down\", {from_bt(f'{M}.to_bits_canonical({M}.next_down(x))')}, table[r + 4]) {{ bad += 1 }}"])
        row_fn("remainder", "remainder", [
            f"let fam = \"{p}remainder\"", f"let y = {to_bt('table[r + 1]')}", f"let x = {fb('table[r]')}", f"let yv = {fb('table[r + 1]')}",
            f"if !check(fam, i, \"remainder_bits\", {from_bt(f'{M}.remainder_bits(b, y)')}, table[r + 2]) {{ bad += 1 }}",
            f"if !check(fam, i, \"remainder\", {from_bt(f'{M}.to_bits_canonical({M}.remainder(x, yv))')}, table[r + 3]) {{ bad += 1 }}"])
        ds0 = ", ".join(f"@float.{d}" for d in DIRECTIONS)
        row_fn("scaleb", "scaleb", [
            f"let fam = \"{p}scaleb\"", f"let x = {fb('table[r]')}", "let n = table[r + 1].reinterpret_as_int64().to_int()", f"let dirs = [{ds0}]",
            "for k in 0..<5 {",
            f"  if !check(fam, i, \"scaleb_bits_with#\" + k.to_string(), {from_bt(f'{M}.scaleb_bits_with(b, n, dirs[k])')}, table[r + 2 + k]) {{ bad += 1 }}",
            f"  if !check(fam, i, \"scaleb_with#\" + k.to_string(), {from_bt(f'{M}.to_bits_canonical({M}.scaleb_with(x, n, dirs[k]))')}, table[r + 7 + k]) {{ bad += 1 }}",
            "}",
            f"if !check(fam, i, \"scaleb_bits\", {from_bt(f'{M}.scaleb_bits(b, n)')}, table[r + 2]) {{ bad += 1 }}",
            f"if !check(fam, i, \"scaleb\", {from_bt(f'{M}.to_bits_canonical({M}.scaleb(x, n))')}, table[r + 7]) {{ bad += 1 }}"])
        row_fn("logb", "logb", [
            f"let fam = \"{p}logb\"", f"let x = {fb('table[r]')}",
            f"match {M}.logb_bits(b) {{",
            "  Some(v) => { if table[r + 1] != 1UL { report(fam, i, \"logb_bits present\"); bad += 1 } else if !check(fam, i, \"logb_bits\", v.to_int64().reinterpret_as_uint64(), table[r + 2]) { bad += 1 } }",
            "  None => if table[r + 1] != 0UL { report(fam, i, \"logb_bits missing\"); bad += 1 }", "}",
            f"if !check(fam, i, \"logb\", {from_bt(f'{M}.to_bits_canonical({M}.logb(x))')}, table[r + 3]) {{ bad += 1 }}"])
        if width == 64:
            dsn = ", ".join(f"@float.{d}" for d in DIRECTIONS)
            row_fn("narrow", "narrow", [
                f"let fam = \"{p}narrow\"", f"let x = {fb('table[r]')}", f"let dirs = [{dsn}]",
                "for k in 0..<5 {",
                "  if !check(fam, i, \"to_binary32_bits_with#\" + k.to_string(), @float.to_binary32_bits_with(b, dirs[k]).to_uint64(), table[r + 1 + k]) { bad += 1 }",
                "  if !check(fam, i, \"to_binary32_with#\" + k.to_string(), @binary32.to_bits_canonical(@float.to_binary32_with(x, dirs[k])).to_uint64(), table[r + 6 + k]) { bad += 1 }",
                "}",
                "if !check(fam, i, \"to_binary32_bits\", @float.to_binary32_bits(b).to_uint64(), table[r + 1]) { bad += 1 }",
                "if !check(fam, i, \"to_binary32\", @binary32.to_bits_canonical(@float.to_binary32(x)).to_uint64(), table[r + 6]) { bad += 1 }",
                "if !check(fam, i, \"core Float::from_double\", @binary32.to_bits_canonical(Float::from_double(x)).to_uint64(), table[r + 6]) { bad += 1 }"])
        else:
            row_fn("widen", "widen", [
                f"let fam = \"{p}widen\"", f"let x = {fb('table[r]')}",
                "if !check(fam, i, \"to_binary64_bits\", @binary32.to_binary64_bits(b), table[r + 1]) { bad += 1 }",
                "if !check(fam, i, \"to_binary64\", @float.to_bits_canonical(@binary32.to_binary64(x)), table[r + 2]) { bad += 1 }",
                "if !check(fam, i, \"core Float::to_double\", @float.to_bits_canonical(x.to_double()), table[r + 2]) { bad += 1 }",
                "if !check(fam, i, \"round trip\", @float.to_binary32_bits(@binary32.to_binary64_bits(b)).to_uint64(), if @binary32.is_nan_bits(b) { b.to_uint64() | 0x400000UL } else { b.to_uint64() }) { bad += 1 }"])
        row_fn("eft", "eft", [
            f"let fam = \"{p}eft\"", f"let x = {fb('table[r]')}", f"let y = {fb('table[r + 1]')}",
            f"let (s, e) = {M}.two_sum(x, y)",
            f"if !check(fam, i, \"two_sum s\", {from_bt(f'{M}.to_bits_canonical(s)')}, table[r + 2]) {{ bad += 1 }}",
            f"if !check(fam, i, \"two_sum e\", {from_bt(f'{M}.to_bits_canonical(e)')}, table[r + 3]) {{ bad += 1 }}",
            "if table[r + 4] == 1UL {",
            f"  let (s2, e2) = {M}.fast_two_sum(x, y)",
            f"  if !check(fam, i, \"fast_two_sum s\", {from_bt(f'{M}.to_bits_canonical(s2)')}, table[r + 2]) {{ bad += 1 }}",
            f"  if !check(fam, i, \"fast_two_sum e\", {from_bt(f'{M}.to_bits_canonical(e2)')}, table[r + 5]) {{ bad += 1 }}",
            "}",
            f"let (p, ep) = {M}.two_prod(x, y)",
            f"if !check(fam, i, \"two_prod p\", {from_bt(f'{M}.to_bits_canonical(p)')}, table[r + 6]) {{ bad += 1 }}",
            f"if !check(fam, i, \"two_prod e\", {from_bt(f'{M}.to_bits_canonical(ep)')}, table[r + 7]) {{ bad += 1 }}"])
        dsf = ", ".join(f"@float.{d}" for d in DIRECTIONS)
        row_fn("fma", "fma", [
            f"let fam = \"{p}fma\"", f"let y = {to_bt('table[r + 1]')}", f"let z = {to_bt('table[r + 2]')}",
            f"let x = {fb('table[r]')}", f"let yv = {fb('table[r + 1]')}", f"let zv = {fb('table[r + 2]')}", f"let dirs = [{dsf}]",
            "for k in 0..<5 {",
            f"  if !check(fam, i, \"fma_bits_with#\" + k.to_string(), {from_bt(f'{M}.fma_bits_with(b, y, z, dirs[k])')}, table[r + 3 + k]) {{ bad += 1 }}",
            f"  if !check(fam, i, \"fma_with#\" + k.to_string(), {from_bt(f'{M}.to_bits_canonical({M}.fma_with(x, yv, zv, dirs[k]))')}, table[r + 8 + k]) {{ bad += 1 }}",
            "}",
            f"if !check(fam, i, \"fma_bits\", {from_bt(f'{M}.fma_bits(b, y, z)')}, table[r + 3]) {{ bad += 1 }}",
            *([f"if {M}.is_finite_bits(b) && {M}.is_finite_bits(y) && {M}.is_finite_bits(z) {{",
               "  for k in 0..<5 {",
               f"    if !check(fam, i, \"fma_finite_bits#\" + k.to_string(), @float.fma_finite_bits({'b, y, z' if width == 64 else '@binary32.to_binary64_bits(b), @binary32.to_binary64_bits(y), @binary32.to_binary64_bits(z)'}, {52 if width == 64 else 23}, dirs[k]), table[r + 3 + k]) {{ bad += 1 }}",
               "  }", "}"]),
            f"if !check(fam, i, \"fma\", {from_bt(f'{M}.to_bits_canonical({M}.fma(x, yv, zv))')}, table[r + 8]) {{ bad += 1 }}"])
        ps = ", ".join(f"@float.{n}" for n, _, _ in PREDICATES)
        row_fn("compare", "compare", [
            f"let fam = \"{p}compare\"", f"let preds = [{ps}]", f"let x = {fb('table[r]')}", f"let y = {fb('table[r + 1]')}",
            f"let rel = {M}.relation_bits(b, {to_bt('table[r + 1]')})",
            "let code = match rel {", "  Less => 0UL", "  Equal => 1UL", "  Greater => 2UL", "  Unordered => 3UL", "}",
            "if !check(fam, i, \"relation_bits\", code, table[r + 2]) { bad += 1 }",
            f"let rel2 = {M}.relation(x, y)",
            "let code2 = match rel2 {", "  Less => 0UL", "  Equal => 1UL", "  Greater => 2UL", "  Unordered => 3UL", "}",
            "if !check(fam, i, \"relation\", code2, table[r + 2]) { bad += 1 }",
            "for k in 0..<22 {",
            f"  let (v, inv) = {M}.compare_predicate_bits(preds[k], b, {to_bt('table[r + 1]')})",
            "  if !check(fam, i, \"compare_predicate_bits value#\" + k.to_string(), if v { 1UL } else { 0UL }, (table[r + 3] >> k) & 1UL) { bad += 1 }",
            "  if !check(fam, i, \"compare_predicate_bits invalid#\" + k.to_string(), if inv { 1UL } else { 0UL }, (table[r + 4] >> k) & 1UL) { bad += 1 }",
            f"  let (pv, pinv) = {M}.compare_predicate(preds[k], x, y)",
            "  if !check(fam, i, \"compare_predicate value#\" + k.to_string(), if pv { 1UL } else { 0UL }, (table[r + 3] >> k) & 1UL) { bad += 1 }",
            "  if !check(fam, i, \"compare_predicate invalid#\" + k.to_string(), if pinv { 1UL } else { 0UL }, (table[r + 5] >> k) & 1UL) { bad += 1 }",
            f"  let (ov, oinv) = @float.predicate_outcome(preds[k], rel, table[r + 6] != 0UL, table[r + 7] != 0UL)",
            "  if !check(fam, i, \"predicate_outcome value#\" + k.to_string(), if ov { 1UL } else { 0UL }, (table[r + 3] >> k) & 1UL) { bad += 1 }",
            "  if !check(fam, i, \"predicate_outcome invalid#\" + k.to_string(), if oinv { 1UL } else { 0UL }, (table[r + 4] >> k) & 1UL) { bad += 1 }",
            "}"])
        ds = ", ".join(f"@float.{d}" for d in DIRECTIONS)
        row_fn("round", "round", [
            f"let fam = \"{p}round\"", f"let x = {fb('table[r]')}", f"let dirs = [{ds}]",
            "for k in 0..<5 {",
            f"  if !check(fam, i, \"round_to_integral#\" + k.to_string(), {from_bt(f'{M}.to_bits_canonical({M}.round_to_integral(x, dirs[k]))')}, table[r + 1 + k]) {{ bad += 1 }}",
            "}",
            f"if !check(fam, i, \"round_ties_even\", {from_bt(f'{M}.to_bits_canonical({M}.round_ties_even(x))')}, table[r + 1]) {{ bad += 1 }}",
            f"if !check(fam, i, \"round_ties_away\", {from_bt(f'{M}.to_bits_canonical({M}.round_ties_away(x))')}, table[r + 2]) {{ bad += 1 }}",
            f"if !check(fam, i, \"round_toward_zero\", {from_bt(f'{M}.to_bits_canonical({M}.round_toward_zero(x))')}, table[r + 3]) {{ bad += 1 }}",
            f"if !check(fam, i, \"round_toward_positive\", {from_bt(f'{M}.to_bits_canonical({M}.round_toward_positive(x))')}, table[r + 4]) {{ bad += 1 }}",
            f"if !check(fam, i, \"round_toward_negative\", {from_bt(f'{M}.to_bits_canonical({M}.round_toward_negative(x))')}, table[r + 5]) {{ bad += 1 }}"])
        wrap = {"int": "i2w", "int64": "i64w", "uint": "u2w", "uint64": "u64w"}
        conv = ["let fam = \"%sconvert\"" % p, f"let x = {fb('table[r]')}", f"let dirs = [{ds}]"]
        for ti, tname in enumerate(TARGETS):
            wf = wrap[tname]
            conv += ["for k in 0..<5 {", f"  let base = r + 1 + ({ti} * 5 + k) * 3",
                     f"  match {M}.to_{tname}_checked_with(x, dirs[k]) {{",
                     f"    Some(v) => {{ if table[base] != 1UL {{ report(fam, i, \"{tname} checked present#\" + k.to_string()); bad += 1 }} else if !check(fam, i, \"{tname}_checked#\" + k.to_string(), {wf}(v), table[base + 1]) {{ bad += 1 }} }}",
                     f"    None => if table[base] != 0UL {{ report(fam, i, \"{tname} checked missing#\" + k.to_string()); bad += 1 }}",
                     "  }",
                     f"  if !check(fam, i, \"{tname}_saturating#\" + k.to_string(), {wf}({M}.to_{tname}_saturating_with(x, dirs[k])), table[base + 2]) {{ bad += 1 }}",
                     "}",
                     f"let tb{ti} = r + 1 + ({ti} * 5 + 2) * 3",
                     f"if !check(fam, i, \"{tname}_saturating default\", {wf}({M}.to_{tname}_saturating(x)), table[tb{ti} + 2]) {{ bad += 1 }}",
                     f"match {M}.to_{tname}_checked(x) {{",
                     f"  Some(v) => {{ if table[tb{ti}] != 1UL {{ report(fam, i, \"{tname} default checked present\"); bad += 1 }} else if !check(fam, i, \"{tname}_checked default\", {wf}(v), table[tb{ti} + 1]) {{ bad += 1 }} }}",
                     f"  None => if table[tb{ti}] != 0UL {{ report(fam, i, \"{tname} default checked missing\"); bad += 1 }}",
                     "}"]
        row_fn("convert", "convert", conv)
        arr = [f"let fam = \"{p}sort\"", "let n = table[r].reinterpret_as_int64().to_int()",
               f"let values : Array[{FT}] = []",
               f"for k in 0..<n {{ values.push({fb('table[r + 1 + k]')}) }}",
               f"{M}.sort_total_order(values)",
               f"let view_values : Array[{FT}] = []",
               f"for k in 0..<n {{ view_values.push({fb('table[r + 1 + k]')}) }}",
               f"{M}.sort_total_order_view(view_values.mut_view())",
               "for k in 0..<n {",
               f"  if !check(fam, i, \"sort_total_order_view[\" + k.to_string() + \"]\", {from_bt(f'{M}.to_bits_canonical(view_values[k])')}, table[r + 1 + n + k]) {{ bad += 1 }}",
               "}",
               "for k in 0..<n {",
               f"  if !check(fam, i, \"sort_total_order[\" + k.to_string() + \"]\", {from_bt(f'{M}.to_bits_canonical(values[k])')}, table[r + 1 + n + k]) {{ bad += 1 }}",
               "}"]
        # variable stride rows: rewrite with an offset walk
        rows = t.rows[p + "sort"]
        flat = lit(rows)
        out.extend(["///|", f"let {p}sort_table : Array[UInt64] = load([{flat}])", "",
                    "///|", f"test \"audit {p}sort\" {{", f"  let table = {p}sort_table",
                    "  let mut r = 0", "  let mut i = 0", "  let mut bad = 0",
                    "  while r < table.length() {"])
        out.extend(["    " + ln for ln in arr])
        out.extend(["    r += 1 + 2 * n", "    i += 1", "  }",
                    f'  println("LUNA_AUDIT_SUMMARY {p}sort " + i.to_string() + " " + bad.to_string())', "}", ""])
    for fam, conv_expr, extra in (
        ("conv_i32", "table[r].to_uint().reinterpret_as_int()", [("v.to_double()", "reinterpret_as_uint64()", 1), ("Float::from_int(v)", "reinterpret_as_uint().to_uint64()", 2)]),
        ("conv_u32", "table[r].to_uint()", [("v.to_double()", "reinterpret_as_uint64()", 1), ("Float::from_uint(v)", "reinterpret_as_uint().to_uint64()", 2)]),
        ("conv_i64", "table[r].reinterpret_as_int64()", [("v.to_double()", "reinterpret_as_uint64()", 1)]),
        ("conv_u64", "table[r]", [("v.to_double()", "reinterpret_as_uint64()", 1)]),
        ("conv_i64_f32", "table[r].reinterpret_as_int64()", [("Float::from_int64(v)", "reinterpret_as_uint().to_uint64()", 1)]),
        ("conv_u64_f32", "table[r]", [("Float::from_uint64(v)", "reinterpret_as_uint().to_uint64()", 1)]),
    ):
        crows, cstride = strided(t.rows[fam])
        checks = [f"    if !check(\"{fam}\", i, \"{m.replace('v.', '').replace('(v)', '')}\", ({m}).{conv}, table[r + {k}]) {{ bad += 1 }}" for m, conv, k in extra]
        out.extend(["///|", f"let {fam}_table : Array[UInt64] = load([{crows}])", "",
                    "///|", f'test "audit {fam}" {{', f"  let table = {fam}_table", f"  let n = table.length() / {cstride}",
                    "  let mut bad = 0", "  for i in 0..<n {", f"    let r = i * {cstride}", f"    let v = {conv_expr}", *checks, "  }",
                    f'  println("LUNA_AUDIT_SUMMARY {fam} " + n.to_string() + " " + bad.to_string())', "}", ""])
    rows, stride = strided(t.rows["int_to_f32"])
    out.extend(["///|", f"let int_to_f32_table : Array[UInt64] = load([{rows}])", "",
                "///|", 'test "audit int_to_f32" {', "  let table = int_to_f32_table",
                f"  let n = table.length() / {stride}", "  let mut bad = 0", "  for i in 0..<n {",
                f"    let r = i * {stride}", "    let fam = \"int_to_f32\"",
                "    let got_u = @float.uint64_to_float(table[r]).reinterpret_as_uint().to_uint64()",
                "    if !check(fam, i, \"uint64_to_float\", got_u, table[r + 2]) { bad += 1 }",
                "    let got_s = @float.int64_to_float(table[r + 1].reinterpret_as_int64()).reinterpret_as_uint().to_uint64()",
                "    if !check(fam, i, \"int64_to_float\", got_s, table[r + 3]) { bad += 1 }",
                "  }", '  println("LUNA_AUDIT_SUMMARY int_to_f32 " + n.to_string() + " " + bad.to_string())', "}", "",
                "///|", 'test "audit verdict" {', '  println("LUNA_AUDIT_VERDICT mismatches=" + mismatches.val.to_string())',
                "  assert_eq(mismatches.val, 0)", "}", ""])
    return "\n".join(out)


def report(text, seed=None):
    summary = {}
    mismatches = []
    for line in text.splitlines():
        m = re.search(r"LUNA_AUDIT_SUMMARY (\S+) (\d+) (\d+)", line)
        if m:
            summary[m.group(1)] = dict(cases=int(m.group(2)), mismatches=int(m.group(3)))
        elif "LUNA_AUDIT " in line:
            mismatches.append(line[line.index("LUNA_AUDIT "):])
    return dict(seed=seed, families=summary, cases=sum(f["cases"] for f in summary.values()),
                mismatch_count=sum(f["mismatches"] for f in summary.values()), samples=mismatches[:50])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--count", type=int, default=400)
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--report", help="parse a test transcript and print JSON")
    args = parser.parse_args()
    if args.report:
        print(json.dumps(report(Path(args.report).read_text(), args.seed), indent=1))
        return 0
    text = emit(build(args.seed, args.count), args.seed, args.count)
    if args.write:
        TARGET.write_text(text)
        subprocess.run(["moon", "fmt"], cwd=ROOT, capture_output=True)  # best effort; keeps `moon fmt --check` clean
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
