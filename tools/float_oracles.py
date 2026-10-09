"""Offline IEEE 754-2019 binary interchange field model for #25.

Python arbitrary-precision divmod extracts fields independently of the MoonBit
mask implementation. No host float NaN materialization and no library output
is used to produce expected results. Class IDs and None's sentinel are only
transcript transport conventions (not public API discriminants).
"""

CLASSES = ["PositiveZero", "NegativeZero", "PositiveSubnormal",
           "NegativeSubnormal", "PositiveNormal", "NegativeNormal",
           "PositiveInfinity", "NegativeInfinity", "SignalingNaN", "QuietNaN"]


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
    return cases
