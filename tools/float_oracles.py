"""Offline IEEE 754-2019 binary interchange field model for #25.

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


def conversion_expression(package, source, target, mode, direction=None, presence=False):
    name, _, _, _, _ = target
    suffix = "_with" if direction is not None else ""
    function = f"{package}.to_{name}_{mode}{suffix}({source}"
    if direction is not None:
        function += f", @float.{direction}"
    function += ")"
    if mode == "checked":
        if presence:
            return f"match {function} {{ Some(_) => 1UL; None => 0UL }}"
        value_expr = "value.to_int64().reinterpret_as_uint64()" if name == "int" else (
            "value.reinterpret_as_uint64()" if name == "int64" else
            "(value.to_uint64() & 0xffffffffUL)" if name == "uint" else "value"
        )
        return f"match {function} {{ Some(value) => {value_expr}; None => 0UL }}"
    return f"({function}).to_int64().reinterpret_as_uint64()" if name == "int" else (
        f"({function}).reinterpret_as_uint64()" if name == "int64" else
        f"(({function}).to_uint64() & 0xffffffffUL)" if name == "uint" else function
    )


def conversion_output(value, target):
    name, _, _, _, _ = target
    if name in ("int", "int64"):
        return value & 0xffffffffffffffff
    if name == "uint":
        return value & 0xffffffff
    return value


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


def generate_conversion_cases():
    cases = []
    rng = random.Random(0x22C0FFEE)
    for width, package in [(64, "@float"), (32, "@binary32")]:
        sign_mask = 1 << (width - 1)
        exponent_mask = 0x7ff0000000000000 if width == 64 else 0x7f800000
        fraction_width, exponent_width = ((52, 11) if width == 64 else (23, 8))
        cases_bits = {0, sign_mask, 1, sign_mask | 1, exponent_mask - 1, sign_mask | (exponent_mask - 1),
                      exponent_mask, sign_mask | exponent_mask, exponent_mask | 1, sign_mask | exponent_mask | 1,
                      exponent_mask | (1 << (fraction_width - 1)), sign_mask | exponent_mask | (1 << (fraction_width - 1))}
        def encode(value):
            if width == 64:
                import struct
                return struct.unpack(">Q", struct.pack(">d", float(value)))[0]
            import struct
            return struct.unpack(">I", struct.pack(">f", float(value)))[0]
        for _, lo, hi, _, _ in INTEGER_TARGETS:
            for boundary in (lo, hi, lo - 1, hi + 1):
                base = encode(boundary)
                cases_bits.add(base)
                if base & sign_mask == 0:
                    if base > 0:
                        cases_bits.add(base - 1)
                    cases_bits.add(base + 1)
                else:
                    cases_bits.add(base + 1)
                    if base > sign_mask:
                        cases_bits.add(base - 1)
        # Deterministic random encodings exercise ordinary, subnormal and extreme exponents.
        cases_bits.update(rng.getrandbits(width) for _ in range(32))
        for raw in sorted(cases_bits):
            finite = decode_finite(raw, width)
            src = (f"0x{raw:016x}UL.reinterpret_as_double()" if width == 64 else
                   f"Float::reinterpret_from_uint(0x{raw:08x}U)")
            for target in INTEGER_TARGETS:
                name, lower, upper, _, _ = target
                for direction, direction_name in ROUNDINGS:
                    rounded_value = None if finite is None else round_fraction(finite, direction)
                    valid = rounded_value is not None and lower <= rounded_value <= upper
                    for mode in ("checked", "saturating"):
                        if mode == "checked":
                            # Value records use zero for an absent optional result;
                            # the separate presence record carries validity.
                            expected_value = conversion_output(rounded_value, target) if valid else 0
                            present_expr = conversion_expression(package, src, target, mode, direction, presence=True)
                            cases.append(dict(
                                id=f"conv{width}_{name}_checked_present_{direction_name}_{raw:x}",
                                inputs=[str(raw)], expression=present_expr, bits=f"{int(valid):016x}",
                            ))
                        else:
                            if rounded_value is None:
                                fraction_mask = (1 << fraction_width) - 1
                                is_infinity = (raw & fraction_mask) == 0 and (raw & exponent_mask) == exponent_mask
                                if is_infinity:
                                    saturated = upper if (raw & sign_mask) == 0 else lower
                                else:
                                    saturated = 0
                            else:
                                saturated = min(max(rounded_value, lower), upper)
                            expected_value = conversion_output(saturated, target)
                        expr = conversion_expression(package, src, target, mode, direction)
                        cases.append(dict(
                            id=f"conv{width}_{name}_{mode}_{direction_name}_{raw:x}",
                            inputs=[str(raw)], expression=expr, bits=f"{expected_value:016x}",
                        ))
    return cases


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


def generate_integer_float_cases():
    cases = []
    signed = [0, 1, -1, 2**24 - 1, 2**24, 2**24 + 1,
              2**53 + 2**29 + 1, -(2**53 + 2**29 + 1),
              2**63 - 1, -(2**63)]
    unsigned = [0, 1, 2**24 - 1, 2**24, 2**24 + 1,
                2**53 + 2**29 + 1, 2**63, 2**64 - 1]
    for value in signed:
        cases.append(dict(
            id=f"i64_to_float_{value}", inputs=[str(value)],
            expression=f"@binary32.to_bits_canonical(@float.int64_to_float({value}L)).to_uint64()",
            bits=f"{binary32_bits_from_integer(value):016x}",
        ))
        cases.append(dict(
            id=f"i64_to_double_{value}", inputs=[str(value)],
            expression=f"({value}L).to_double().reinterpret_as_uint64()",
            bits=f"{struct.unpack('>Q', struct.pack('>d', float(value)))[0]:016x}",
        ))
    for value in unsigned:
        cases.append(dict(
            id=f"u64_to_float_{value}", inputs=[str(value)],
            expression=f"@binary32.to_bits_canonical(@float.uint64_to_float({value}UL)).to_uint64()",
            bits=f"{binary32_bits_from_integer(value):016x}",
        ))
        cases.append(dict(
            id=f"u64_to_double_{value}", inputs=[str(value)],
            expression=f"({value}UL).to_double().reinterpret_as_uint64()",
            bits=f"{struct.unpack('>Q', struct.pack('>d', float(value)))[0]:016x}",
        ))
    return cases
