"""Offline IEEE 754-2019 binary interchange field model for #25 and #22.

The #24 rounding oracle decodes finite values to exact Fractions and applies
the five directions to rational values, independently of the bit algorithm.
No host float NaN materialization or library output produces expected results.
Class IDs and None's sentinel are transcript conventions, not public API IDs.
"""
from fractions import Fraction
import random
import struct


CLASSES = ["PositiveZero", "NegativeZero", "PositiveSubnormal",
           "NegativeSubnormal", "PositiveNormal", "NegativeNormal",
           "PositiveInfinity", "NegativeInfinity", "SignalingNaN", "QuietNaN"]

ROUNDINGS = [
    ("TiesToEven", "ties_even"), ("TiesToAway", "ties_away"),
    ("TowardZero", "toward_zero"), ("TowardPositive", "toward_positive"),
    ("TowardNegative", "toward_negative"),
]

INTEGER_TARGETS = [
    ("int", -(1 << 31), (1 << 31) - 1, "Int", "to_int"),
    ("int64", -(1 << 63), (1 << 63) - 1, "Int64", "to_int64"),
    ("uint", 0, (1 << 32) - 1, "UInt", "to_uint"),
    ("uint64", 0, (1 << 64) - 1, "UInt64", "to_uint64"),
]


def decode_finite(bits, width):
    frac_width, exp_width = ((52, 11) if width == 64 else (23, 8))
    sign = -1 if bits >> (width - 1) else 1
    fraction_mask = (1 << frac_width) - 1
    fraction = bits & fraction_mask
    exponent = (bits >> frac_width) & ((1 << exp_width) - 1)
    if exponent == (1 << exp_width) - 1:
        return None
    bias = (1 << (exp_width - 1)) - 1
    if exponent == 0:
        significand, power = fraction, 1 - bias - frac_width
    else:
        significand, power = (1 << frac_width) | fraction, exponent - bias - frac_width
    magnitude = Fraction(significand << power, 1) if power >= 0 else Fraction(significand, 1 << -power)
    return sign * magnitude


def round_fraction(value, direction):
    lower = value.numerator // value.denominator
    remainder = value - lower
    if direction == "TowardPositive":
        return lower if remainder == 0 else lower + 1
    if direction == "TowardNegative":
        return lower
    if direction == "TowardZero":
        return int(value)
    twice = remainder * 2
    if twice < 1:
        return lower
    if twice > 1:
        return lower + 1
    if direction == "TiesToAway":
        return lower if value < 0 else lower + 1
    return lower if lower % 2 == 0 else lower + 1


def class_encoder():
    return ['  fn class_id(value : @float.Classification) -> UInt64 {',
            '    match value {',
            *[f'      @float.{name} => {i}UL' for i, name in enumerate(CLASSES)],
            '    }', '  }']


def generate_float_cases():
    cases = []
    for width, fraction_width, exponent_width, package in [
        (64, 52, 11, '@float'), (32, 23, 8, '@binary32'),
    ]:
        sign_unit = 2 ** (width - 1)
        fraction_unit = 2 ** fraction_width
        exponent_limit = 2 ** exponent_width - 1
        quiet_unit = fraction_unit // 2
        payload_limit = quiet_unit - 1
        canonical = exponent_limit * fraction_unit + quiet_unit
        suffix = 'UL' if width == 64 else 'U'

        def literal(n):
            return f'0x{n:0{width // 4}x}{suffix}'

        def fields(n):
            sign, magnitude = divmod(n, sign_unit)
            exponent, fraction = divmod(magnitude, fraction_unit)
            return sign, exponent, fraction

        def nan(n):
            _, exponent, fraction = fields(n)
            return exponent == exponent_limit and fraction != 0

        def normalize(n):
            return canonical if nan(n) else n

        def classification(n):
            sign, exponent, fraction = fields(n)
            if exponent == exponent_limit:
                if fraction:
                    return 9 if fraction >= quiet_unit else 8
                return 6 + sign
            if exponent == 0:
                return (2 if fraction else 0) + sign
            return 4 + sign

        def value(n):
            return (f'{literal(n)}.reinterpret_as_double()' if width == 64
                    else f'Float::reinterpret_from_uint({literal(n)})')

        def widen(expr):
            return expr if width == 64 else f'(({expr}).to_uint64() & 0xffffffffUL)'

        def add(ident, expression, expected, inputs):
            cases.append(dict(id=f'b{width}_{ident}', inputs=[str(n) for n in inputs],
                              expression=expression, bits=f'{expected:016x}'))

        def round_integral(n, direction):
            sign, exponent, fraction = fields(n)
            if exponent == exponent_limit:
                return canonical if fraction else n
            sign_bits = sign * sign_unit
            if exponent == 0 and fraction == 0:
                return n

            bias = exponent_limit // 2
            if exponent == 0:
                significand = fraction
                power = 1 - bias - fraction_width
            else:
                significand = (1 << fraction_width) | fraction
                power = exponent - bias - fraction_width
            value = Fraction(significand << power, 1) if power >= 0 else Fraction(significand, 1 << -power)
            if sign:
                value = -value
            if value.denominator == 1:
                return n

            lower = value.numerator // value.denominator
            remainder = value - lower
            upper = lower if remainder == 0 else lower + 1
            if direction == 'toward_positive':
                rounded = upper
            elif direction == 'toward_negative':
                rounded = lower
            elif direction == 'toward_zero':
                rounded = lower if value >= 0 else upper
            elif direction == 'ties_away':
                twice = remainder * 2
                if twice < 1:
                    rounded = lower
                elif twice > 1:
                    rounded = upper
                else:
                    rounded = upper if value >= 0 else lower
            else:
                twice = remainder * 2
                if twice < 1:
                    rounded = lower
                elif twice > 1:
                    rounded = upper
                else:
                    rounded = lower if lower % 2 == 0 else upper

            if rounded == 0:
                return sign_bits
            magnitude = abs(rounded)
            top_bit = magnitude.bit_length() - 1
            encoded_exponent = top_bit + bias
            encoded_fraction = (magnitude - (1 << top_bit)) << (fraction_width - top_bit)
            return sign_bits | (encoded_exponent << fraction_width) | encoded_fraction

        magnitudes = [
            ('zero', 0), ('min_subnormal', 1),
            ('max_subnormal', fraction_unit - 1), ('min_normal', fraction_unit),
            ('max_normal', exponent_limit * fraction_unit - 1),
            ('infinity', exponent_limit * fraction_unit),
            ('snan_min', exponent_limit * fraction_unit + 1),
            ('snan_max', exponent_limit * fraction_unit + payload_limit),
            ('qnan_zero', canonical), ('qnan_max', canonical + payload_limit),
        ]
        for sign in (0, 1):
            for name, magnitude in magnitudes:
                n = sign * sign_unit + magnitude
                ident = f'{name}_{"minus" if sign else "plus"}'
                raw = literal(n)
                v = value(n)
                add(f'{ident}_class', f'class_id({package}.classify_bits({raw}))', classification(n), [n])
                add(f'{ident}_portable_class', f'class_id({package}.portable_classify({v}))', classification(normalize(n)), [n])
                predicates = dict(is_nan_bits=nan(n),
                                  is_signaling_bits=nan(n) and fields(n)[2] < quiet_unit,
                                  is_canonical_bits=True,
                                  is_sign_minus_bits=bool(sign),
                                  is_subnormal_bits=fields(n)[1] == 0 and fields(n)[2] != 0,
                                  is_finite_bits=fields(n)[1] != exponent_limit,
                                  is_zero_bits=magnitude == 0)
                for operation, expected in predicates.items():
                    add(f'{ident}_{operation}', f'if {package}.{operation}({raw}) {{ 1UL }} else {{ 0UL }}', int(expected), [n])
                raw_results = dict(negate_bits=(1-sign)*sign_unit+magnitude,
                                   abs_bits=magnitude, canonicalize_nan_bits=normalize(n))
                for operation, expected in raw_results.items():
                    add(f'{ident}_{operation}', widen(f'{package}.{operation}({raw})'), expected, [n])
                payload = fields(n)[2] % quiet_unit if nan(n) else None
                add(f'{ident}_get_payload', f'match {package}.get_payload_bits({raw}) {{ Some(p) => {widen("p")}; None => 0xffffffffffffffffUL }}', payload if payload is not None else 2**64-1, [n])
                numeric_results = dict(portable_negate=normalize((1-sign)*sign_unit+magnitude),
                                       portable_abs=normalize(magnitude), canonicalize_nan=normalize(n))
                for operation, expected in numeric_results.items():
                    add(f'{ident}_{operation}', widen(f'{package}.to_bits_canonical({package}.{operation}({v}))'), expected, [n])
                for donor in (0, sign_unit, canonical + payload_limit, canonical + sign_unit + payload_limit):
                    donor_sign = fields(normalize(donor))[0]
                    add(f'{ident}_copy_raw_{donor:x}', widen(f'{package}.copy_sign_bits({raw}, {literal(donor)})'), fields(donor)[0]*sign_unit+magnitude, [n, donor])
                    add(f'{ident}_copy_portable_{donor:x}', widen(f'{package}.to_bits_canonical({package}.portable_copy_sign({v}, {value(donor)}))'), normalize(donor_sign*sign_unit+magnitude), [n, donor])

        for sign in (0, 1):
            for payload in (0, 1, payload_limit, quiet_unit, 2**width-1):
                for operation, signaling in [('set_payload_bits', False), ('set_payload_signaling_bits', True)]:
                    valid = payload <= payload_limit and (not signaling or payload != 0)
                    expected = sign*sign_unit + exponent_limit*fraction_unit + (0 if signaling else quiet_unit) + payload if valid else 2**64-1
                    expression = f'match {package}.{operation}({literal(payload)}, sign_minus={str(bool(sign)).lower()}) {{ Some(p) => {widen("p")}; None => 0xffffffffffffffffUL }}'
                    add(f'{operation}_{sign}_{payload:x}', expression, expected, [payload, sign])

        round_inputs = [
            ('zero', 0),
            ('neg_zero', sign_unit),
            ('min_subnormal', 1),
            ('neg_min_subnormal', sign_unit | 1),
            ('max_subnormal', fraction_unit - 1),
            ('neg_max_subnormal', sign_unit | (fraction_unit - 1)),
            ('max_finite', (exponent_limit - 1) * fraction_unit + fraction_unit - 1),
            ('neg_max_finite', sign_unit | ((exponent_limit - 1) * fraction_unit + fraction_unit - 1)),
            ('2p5', (0x4004000000000000 if width == 64 else 0x40200000)),
            ('neg2p5', (0xc004000000000000 if width == 64 else 0xc0200000)),
            ('1p5', (0x3ff8000000000000 if width == 64 else 0x3fc00000)),
            ('3p5', (0x400c000000000000 if width == 64 else 0x40600000)),
            ('neg1p5', (0xbff8000000000000 if width == 64 else 0xbfc00000)),
            ('neg3p5', (0xc00c000000000000 if width == 64 else 0xc0600000)),
            ('half', (0x3fe0000000000000 if width == 64 else 0x3f000000)),
            ('neg_half', (0xbfe0000000000000 if width == 64 else 0xbf000000)),
            ('three_quarters', (0x3fe8000000000000 if width == 64 else 0x3f400000)),
            ('neg_three_quarters', (0xbfe8000000000000 if width == 64 else 0xbf400000)),
            ('below_half', (0x3fdfffffffffffff if width == 64 else 0x3effffff)),
            ('below_one', (0x3fefffffffffffff if width == 64 else 0x3f7fffff)),
            ('exponent_tie', (0x4320000000000001 if width == 64 else 0x4a800001)),
            ('boundary_tie', (0x432fffffffffffff if width == 64 else 0x4affffff)),
            ('neg_fraction', (0xbfd3333333333333 if width == 64 else 0xbe99999a)),
            ('large', (0x4330000000000001 if width == 64 else 0x4b000001)),
            ('snan', (0x7ff0000000000001 if width == 64 else 0x7f800001)),
            ('qnan', (0x7ff8000000000000 if width == 64 else 0x7fc00000)),
            ('neg_qnan', (0xfff8000000000000 if width == 64 else 0xffc00000)),
            ('pos_inf', (0x7ff0000000000000 if width == 64 else 0x7f800000)),
            ('neg_inf', (0xfff0000000000000 if width == 64 else 0xff800000)),
        ]
        directions = [
            ('ties_even', 'TiesToEven'), ('ties_away', 'TiesToAway'),
            ('toward_zero', 'TowardZero'), ('toward_positive', 'TowardPositive'),
            ('toward_negative', 'TowardNegative'),
        ]
        for name, n in round_inputs:
            raw = literal(n)
            v = value(n)
            for direction, constructor in directions:
                expression = f'{package}.to_bits_canonical({package}.round_to_integral({v}, @float.{constructor}))'
                add(f'round_{direction}_{name}', widen(expression), round_integral(n, direction), [n])

        order_samples = [
            sign_unit | (exponent_limit * fraction_unit) | quiet_unit | 2,
            sign_unit | (exponent_limit * fraction_unit) | quiet_unit | 1,
            sign_unit | (exponent_limit * fraction_unit) | 2,
            sign_unit | (exponent_limit * fraction_unit) | 1,
            sign_unit | (exponent_limit * fraction_unit),
            sign_unit | (exponent_limit - 1) * fraction_unit + fraction_unit - 1,
            sign_unit | 1,
            sign_unit | fraction_unit,
            sign_unit | (fraction_unit - 1),
            sign_unit,
            0,
            1,
            fraction_unit - 1,
            (0x3ff0000000000000 if width == 64 else 0x3f800000),
            (0xbff0000000000000 if width == 64 else 0xbf800000),
            fraction_unit,
            (exponent_limit - 1) * fraction_unit + fraction_unit - 1,
            exponent_limit * fraction_unit,
            exponent_limit * fraction_unit | 1,
            exponent_limit * fraction_unit | 2,
            exponent_limit * fraction_unit | quiet_unit,
            exponent_limit * fraction_unit | quiet_unit | 1,
            exponent_limit * fraction_unit | quiet_unit | 2,
            sign_unit | exponent_limit * fraction_unit | quiet_unit,
        ]

        def order_key(n):
            transformed = n ^ (sign_unit - 1 if n & sign_unit else 0)
            return transformed - (1 << width) if transformed & sign_unit else transformed

        for x in order_samples:
            for y in order_samples:
                add(
                    f'total_order_bits_{x:x}_{y:x}',
                    f'if {package}.total_order_bits({literal(x)}, {literal(y)}) {{ 1UL }} else {{ 0UL }}',
                    int(order_key(x) <= order_key(y)), [x, y],
                )
                nx, ny = normalize(x), normalize(y)
                vx, vy = value(x), value(y)
                add(
                    f'total_order_{x:x}_{y:x}',
                    f'if {package}.portable_total_order({vx}, {vy}) {{ 1UL }} else {{ 0UL }}',
                    int(order_key(nx) <= order_key(ny)), [x, y],
                )
                if nan(x) or nan(y):
                    min_expected = max_expected = canonical
                else:
                    min_expected = x if order_key(x) <= order_key(y) else y
                    max_expected = y if order_key(x) <= order_key(y) else x
                add(
                    f'minimum_{x:x}_{y:x}',
                    widen(f'{package}.to_bits_canonical({package}.minimum({vx}, {vy}))'),
                    min_expected, [x, y],
                )
                add(
                    f'maximum_{x:x}_{y:x}',
                    widen(f'{package}.to_bits_canonical({package}.maximum({vx}, {vy}))'),
                    max_expected, [x, y],
                )
    return cases


# ---------------------------------------------------------------------------
# Integer conversion suite (#22).  Everything below is an exact-arithmetic model
# (Fraction/int); no library output feeds an expected value.  The generated
# MoonBit test loops over a compact table of inputs once instead of expanding
# every (input, target, direction, mode) combination into source lines.
# ---------------------------------------------------------------------------
FNV_OFFSET = 0xcbf29ce484222325
FNV_PRIME = 0x100000001b3
MASK64 = (1 << 64) - 1
INTEGER_FLOAT_CHUNK = 32


def fnv_fold(h, value):
    return ((h ^ value) * FNV_PRIME) & MASK64


def binary32_bits_from_integer(value):
    magnitude = abs(value)
    if magnitude == 0:
        return 0
    top = magnitude.bit_length() - 1
    if top <= 23:
        significand = magnitude << (23 - top)
    else:
        shift = top - 23
        significand = magnitude >> shift
        remainder = magnitude & ((1 << shift) - 1)
        halfway = 1 << (shift - 1)
        if remainder > halfway or (remainder == halfway and significand & 1):
            significand += 1
    if significand == 1 << 24:
        top += 1
        significand = 1 << 23
    bits = ((top + 127) << 23) | (significand & 0x7fffff)
    return bits | (0x80000000 if value < 0 else 0)


def nearest_binary32_bits(value):
    """Cross-check of binary32_bits_from_integer using Python's exact round-half-even."""
    magnitude = abs(value)
    if magnitude == 0:
        return 0
    exponent = magnitude.bit_length() - 1
    if exponent <= 23:
        significand = magnitude << (23 - exponent)
    else:
        significand = round(Fraction(magnitude, 1 << (exponent - 23)))
    if significand == 1 << 24:
        exponent, significand = exponent + 1, 1 << 23
    return ((exponent + 127) << 23 | (significand & 0x7fffff)) | (0x80000000 if value < 0 else 0)


def exact_encode(value, width):
    """Bits of the binary format holding `value` exactly, else None."""
    try:
        f = float(value)
        if Fraction(f) != value:
            return None
        if width == 64:
            return struct.unpack(">Q", struct.pack(">d", f))[0]
        raw = struct.pack(">f", f)
        if Fraction(struct.unpack(">f", raw)[0]) != value:
            return None
        return struct.unpack(">I", raw)[0]
    except OverflowError:
        return None


def conversion_inputs(width):
    sign = 1 << (width - 1)
    fraction_width = 52 if width == 64 else 23
    exponent_mask = (0x7ff if width == 64 else 0xff) << fraction_width
    bits = set()

    def with_ulps(raw):
        magnitude = raw & (sign - 1)
        for delta in (-1, 0, 1):
            neighbor = magnitude + delta
            if 0 <= neighbor <= exponent_mask:
                bits.add(raw & sign | neighbor)

    def nearest_encode(v):
        if width == 64:
            return struct.unpack(">Q", struct.pack(">d", float(v)))[0]
        try:
            return struct.unpack(">I", struct.pack(">f", float(v)))[0]
        except OverflowError:
            return None

    def add_value(value, nearest=False):
        for v in (value, -value):
            raw = exact_encode(v, width)
            if raw is None and nearest:
                raw = nearest_encode(v)
            if raw is not None:
                with_ulps(raw)

    for raw in (0, sign, 1, sign | 1, (1 << fraction_width) - 1, 1 << fraction_width,
                exponent_mask - 1, sign | (exponent_mask - 1), exponent_mask, sign | exponent_mask,
                exponent_mask | 1, sign | exponent_mask | 1,
                exponent_mask | (1 << (fraction_width - 1)), sign | exponent_mask | (1 << (fraction_width - 1)),
                exponent_mask | ((1 << (fraction_width - 1)) - 1) | 1,
                sign | exponent_mask | (1 << (fraction_width - 1)) | 0x155):
        bits.add(raw)
    # +-0, +-0.5 and the eighths around small integers.
    for numerator in range(0, 8 * 9):
        add_value(Fraction(numerator, 8))
    # Halfway and quarter points next to powers of two (the carry boundary of
    # the significand), and the 2^k sweep with its neighbouring ulps.
    for j in range(0, 70):
        for delta in (Fraction(-1, 2), Fraction(1, 2), Fraction(-1, 4), Fraction(1, 4)):
            add_value(Fraction(2 ** j) + delta)
        add_value(Fraction(2 ** j))
    for j in range(1, 5):
        add_value(Fraction(1, 2 ** j))
    # Neighbourhoods of every target bound: exact where representable, and the
    # nearest encodings otherwise (the exact value of the encoding is modelled).
    for bound in (1 << 31, 1 << 32, 1 << 63, 1 << 64):
        for offset in range(-3, 4):
            for frac in (Fraction(0), Fraction(1, 8), Fraction(1, 4), Fraction(1, 2), Fraction(3, 4)):
                add_value(Fraction(bound + offset) + frac)
            add_value(Fraction(bound + offset), nearest=True)
    rng = random.Random(0x22C0FFEE + width)
    bits.update(rng.getrandbits(width) for _ in range(64))
    return sorted(bits)


def round_token(finite, direction):
    value = round_fraction(finite, direction)
    if value >= 1 << 64:
        return "P", value
    if value <= -(1 << 64):
        return "Q", value
    return f"{'-' if value < 0 else '+'}{abs(value):x}", value


def conversion_bits(value, name):
    return value & (0xffffffff if name == "uint" else MASK64)


def conversion_expectation(token, value, target):
    """(present, checked value bits, saturating bits) for one integer target."""
    name, lower, upper, _, _ = target
    if token == "N":
        return 0, 0, 0
    if token in ("P", "Q"):
        return 0, 0, conversion_bits(upper if token == "P" else lower, name)
    valid = lower <= value <= upper
    saturated = min(max(value, lower), upper)
    return int(valid), conversion_bits(value, name) if valid else 0, conversion_bits(saturated, name)


def conversion_table(width):
    lines, records = [], []
    fraction_width = 52 if width == 64 else 23
    exponent_mask = (0x7ff if width == 64 else 0xff) << fraction_width
    for raw in conversion_inputs(width):
        finite = decode_finite(raw, width)
        magnitude = raw & ((1 << (width - 1)) - 1)
        negative = bool(raw >> (width - 1))
        tokens, values = [], []
        for direction, _ in ROUNDINGS:
            if finite is None:
                if magnitude > exponent_mask:
                    token, value = "N", None
                else:
                    token, value = ("Q" if negative else "P"), None
            else:
                token, value = round_token(finite, direction)
            tokens.append(token)
            values.append(value)
        h = FNV_OFFSET
        for target in INTEGER_TARGETS:
            for d in range(6):
                index = 2 if d == 5 else d  # the default functions round toward zero
                for item in conversion_expectation(tokens[index], values[index], target):
                    h = fnv_fold(h, item)
        digits = f"{raw:0{width // 4}x}"
        lines.append(f"{digits} " + " ".join(tokens))
        records.append((f"conv{width}_{digits}", f"{h:016x}"))
    return lines, records


def integer_float_inputs():
    unsigned = set()

    def add(v):
        if 0 <= v < 1 << 64:
            unsigned.add(v)

    for k in range(64):
        for delta in (-1, 0, 1):
            add((1 << k) + delta)
    # Halfway and just-beside-halfway remainders for 24- and 53-bit significands.
    for precision, max_shift in ((24, 40), (53, 11)):
        for significand in (1 << (precision - 1), (1 << (precision - 1)) + 1, (1 << precision) - 1):
            for shift in range(1, max_shift + 1):
                half = 1 << (shift - 1)
                for remainder in (0, half - 1, half, half + 1, (1 << shift) - 1):
                    add((significand << shift) + remainder)
    for v in (2 ** 64 - 1, 2 ** 64 - 2 ** 39, 2 ** 53 + 2 ** 29 + 1, 2 ** 63, 2 ** 63 - 1,
              2 ** 53 + 1, 2 ** 53 + 3, 2 ** 24 + 1, 2 ** 24 + 3):
        for delta in (-2, -1, 0, 1, 2):
            add(v + delta)
    rng = random.Random(0x22C0FFEF)
    for _ in range(96):
        add(rng.getrandbits(rng.randint(1, 64)))
    signed = set()
    for v in unsigned:
        if v < 1 << 63:
            signed.update((v, -v))
    signed.add(-(1 << 63))
    return sorted(signed), sorted(unsigned)


def integer_float_table(values, name):
    lines, records, h, count = [], [], FNV_OFFSET, 0
    for v in values:
        f32 = binary32_bits_from_integer(v)
        assert f32 == nearest_binary32_bits(v), v
        f64 = struct.unpack(">Q", struct.pack(">d", float(v)))[0]
        lines.append(f"{v & MASK64:016x} {f32:08x} {f64:016x}")
        h = fnv_fold(fnv_fold(h, f32), f64)
        count += 1
        if count % INTEGER_FLOAT_CHUNK == 0:
            records.append((f"{name}_float_{count // INTEGER_FLOAT_CHUNK - 1}", f"{h:016x}"))
            h = FNV_OFFSET
    if count % INTEGER_FLOAT_CHUNK:
        records.append((f"{name}_float_{count // INTEGER_FLOAT_CHUNK}", f"{h:016x}"))
    return lines, records


def string_table(name, lines):
    return ["///|", f"let {name} : String ="] + [f"  #|{line}" for line in lines]


MBT_RUNTIME = r'''
///|
let fnv_offset : UInt64 = 0xcbf29ce484222325UL

///|
fn fnv_fold(h : UInt64, v : UInt64) -> UInt64 {
  (h ^ v) * 0x100000001b3UL
}

///|
fn emit_record(id : String, value : UInt64) -> Unit {
  let hex = value.to_string(radix=16)
  let padded = "0".repeat(16 - hex.length()) + hex
  println("LUNA_BITS " + id + " " + padded)
}

///|
fn parse_hex(s : StringView) -> UInt64 {
  let mut v = 0UL
  for c in s {
    let digit = if c >= '0' && c <= '9' { c.to_int() - 48 } else { c.to_int() - 87 }
    v = (v << 4) | digit.to_uint64()
  }
  v
}

///|
/// The exact rounded integer of one input and direction: `kind` 0 is the finite
/// integer `(-1)^neg * mag`, 1 is NaN, 2 is any value >= 2^64 (or +inf) and
/// 3 is any value <= -2^64 (or -inf).
struct Rounded {
  kind : Int
  neg : Bool
  mag : UInt64
}

///|
fn parse_rounded(s : String) -> Rounded {
  if s == "N" {
    { kind: 1, neg: false, mag: 0UL }
  } else if s == "P" {
    { kind: 2, neg: false, mag: 0UL }
  } else if s == "Q" {
    { kind: 3, neg: true, mag: 0UL }
  } else {
    { kind: 0, neg: s.has_prefix("-"), mag: parse_hex(s[1:]) }
  }
}

///|
/// Targets: 0 Int, 1 Int64, 2 UInt, 3 UInt64.  Returns the largest negative
/// magnitude and the largest positive value.
fn target_limits(t : Int) -> (UInt64, UInt64) {
  match t {
    0 => (0x80000000UL, 0x7fffffffUL)
    1 => (0x8000000000000000UL, 0x7fffffffffffffffUL)
    2 => (0UL, 0xffffffffUL)
    _ => (0UL, 0xffffffffffffffffUL)
  }
}

///|
fn encode_integer(t : Int, neg : Bool, mag : UInt64) -> UInt64 {
  let v = if neg { 0UL - mag } else { mag }
  if t == 2 {
    v & 0xffffffffUL
  } else {
    v
  }
}

///|
/// Expected result of mode `m` (0 presence, 1 checked value, 2 saturating) on a
/// rounded integer.
fn model_value(r : Rounded, t : Int, m : Int) -> UInt64 {
  let (neg_limit, pos_limit) = target_limits(t)
  let present = r.kind == 0 &&
    (if r.neg { r.mag <= neg_limit } else { r.mag <= pos_limit })
  match m {
    0 => if present { 1UL } else { 0UL }
    1 => if present { encode_integer(t, r.neg, r.mag) } else { 0UL }
    _ =>
      if r.kind == 1 {
        0UL
      } else if r.kind == 3 || (r.kind == 0 && r.neg && r.mag > neg_limit) {
        encode_integer(t, true, neg_limit)
      } else if r.kind == 2 || (!r.neg && r.mag > pos_limit) {
        encode_integer(t, false, pos_limit)
      } else {
        encode_integer(t, r.neg, r.mag)
      }
  }
}

///|
let directions : Array[@float.RoundingDirection] = [
  TiesToEven,
  TiesToAway,
  TowardZero,
  TowardPositive,
  TowardNegative,
]

///|
let direction_names : Array[String] = [
  "TiesToEven", "TiesToAway", "TowardZero", "TowardPositive", "TowardNegative", "default",
]
'''


def mbt_conversion_dispatch(width):
    package, source = ("@float", "Double") if width == 64 else ("@binary32", "Float")
    lines = ["///|", f"fn actual{width}(x : {source}, t : Int, m : Int, d : Int) -> UInt64 {{", "  match (t, m) {"]
    for index, (name, _, _, _, _) in enumerate(INTEGER_TARGETS):
        for mode_index, mode in enumerate(("presence", "checked", "saturating")):
            api_mode = "saturating" if mode == "saturating" else "checked"
            default_call = f"{package}.to_{name}_{api_mode}(x)"
            with_call = f"{package}.to_{name}_{api_mode}_with(x, directions[d])"

            def wrap(call):
                if mode == "presence":
                    return f"match {call} {{ Some(_) => 1UL; None => 0UL }}"
                if mode == "checked":
                    value = {"int": "v.to_int64().reinterpret_as_uint64()", "int64": "v.reinterpret_as_uint64()",
                             "uint": "v.to_uint64() & 0xffffffffUL", "uint64": "v"}[name]
                    return f"match {call} {{ Some(v) => {value}; None => 0UL }}"
                return {"int": f"({call}).to_int64().reinterpret_as_uint64()",
                        "int64": f"({call}).reinterpret_as_uint64()",
                        "uint": f"({call}).to_uint64() & 0xffffffffUL", "uint64": call}[name]
            lines.append(f"    ({index}, {mode_index}) => if d == 5 {{ {wrap(default_call)} }} else {{ {wrap(with_call)} }}")
    lines.extend(["    _ => 0UL", "  }", "}"])
    return lines


def mbt_conversion_test(width):
    source = "raw.reinterpret_as_double()" if width == 64 else "Float::reinterpret_from_uint(raw.to_uint())"
    return [
        "///|", f'test "integer conversion oracle binary{width}" {{',
        f'  for line in conv{width}_table.split("\\n") {{',
        "    if line.length() == 0 { continue }",
        "    let fields : Array[String] = line.split(\" \").map(s => s.to_owned()).collect()",
        "    let raw = parse_hex(fields[0])",
        f"    let x = {source}",
        "    let rounded = Array::makei(5, i => parse_rounded(fields[i + 1]))",
        "    let mut h = fnv_offset",
        "    for t in 0..<4 {",
        "      for d in 0..<6 {",
        "        let r = rounded[if d == 5 { 2 } else { d }]",
        "        for m in 0..<3 {",
        f"          let actual = actual{width}(x, t, m, d)",
        "          let expected = model_value(r, t, m)",
        "          if actual != expected {",
        f'            fail("binary{width} " + fields[0] + " target " + t.to_string() + " mode " + m.to_string() + " " + direction_names[d] + ": " + actual.to_string(radix=16) + " != " + expected.to_string(radix=16))',
        "          }",
        "          h = fnv_fold(h, actual)",
        "        }", "      }", "    }",
        f'    emit_record("conv{width}_" + fields[0], h)',
        "  }", "}",
    ]


def mbt_integer_float_test(name, signed):
    raw_to = "raw.reinterpret_as_int64()" if signed else "raw"
    call32 = "@float.int64_to_float(v)" if signed else "@float.uint64_to_float(v)"
    return [
        "///|", f'test "integer to float oracle {name}" {{',
        "  let mut h = fnv_offset", "  let mut count = 0", "  let mut chunk = 0",
        f'  for line in {name}_float_table.split("\\n") {{',
        "    if line.length() == 0 { continue }",
        "    let fields : Array[String] = line.split(\" \").map(s => s.to_owned()).collect()",
        "    let raw = parse_hex(fields[0])",
        f"    let v = {raw_to}",
        f"    let actual32 = @binary32.to_bits_canonical({call32}).to_uint64()",
        "    let actual64 = v.to_double().reinterpret_as_uint64()",
        "    if actual32 != parse_hex(fields[1]) || actual64 != parse_hex(fields[2]) {",
        f'      fail("{name} " + fields[0] + ": " + actual32.to_string(radix=16) + " " + actual64.to_string(radix=16))',
        "    }",
        "    h = fnv_fold(fnv_fold(h, actual32), actual64)",
        "    count += 1",
        f"    if count % {INTEGER_FLOAT_CHUNK} == 0 {{",
        f'      emit_record("{name}_float_" + chunk.to_string(), h)',
        "      chunk += 1", "      h = fnv_offset", "    }", "  }",
        f"  if count % {INTEGER_FLOAT_CHUNK} != 0 {{",
        f'    emit_record("{name}_float_" + chunk.to_string(), h)', "  }", "}",
    ]


def conversion_suite():
    """Return (records, MoonBit lines, JSON fixture tables) for the conversion tests."""
    records, lines, tables = [], MBT_RUNTIME.splitlines(), {}
    for width in (64, 32):
        table, recs = conversion_table(width)
        records += recs
        tables[f"binary{width}"] = table
        lines += string_table(f"conv{width}_table", table) + mbt_conversion_dispatch(width) + mbt_conversion_test(width)
    signed, unsigned = integer_float_inputs()
    for name, values, is_signed in (("i64", signed, True), ("u64", unsigned, False)):
        table, recs = integer_float_table(values, name)
        records += recs
        tables[name] = table
        lines += string_table(f"{name}_float_table", table) + mbt_integer_float_test(name, is_signed)
    return records, lines, tables
