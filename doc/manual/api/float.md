# Float classification and bit API

The package `Luna-Flow/luna-utils/float` operates on binary64 (`Double`, `UInt64` bits). `Luna-Flow/luna-utils/float/binary32` exposes the same function names for binary32 (`Float`, `UInt` bits) and shares the parent `Classification` enum. No host math or floating-point arithmetic is used by the raw-bit operations.

A raw integer encoding preserves NaN sign, signaling state and payload exactly. A numeric value does not preserve that information portably, especially on JavaScript. Numeric NaN is detected by `x != x`; `portable_classify` returns `QuietNaN` without inspecting its sign or payload. Keep signaling NaNs as integers when their representation matters.

## Classification and predicates

`classify_bits(bits)` distinguishes signaling NaN, quiet NaN, positive/negative infinity, normal, subnormal and zero. `portable_classify(x)` uses the same classes for non-NaN numbers and returns `QuietNaN` for every numeric NaN. `radix()` returns 2. The generated interfaces define the exact constructor names.

Predicates have raw `*_bits` and portable numeric forms. `is_signaling_bits` inspects the quiet bit; `portable_is_signaling` always returns `false` because signaling state is not portable. Binary interchange encodings are canonical, so both `is_canonical_bits` and `portable_is_canonical` always return `true`. For numeric NaN, sign-sensitive predicates must not infer a host sign. Consult the generated interface and conformance tests for the conservative numeric observations.

## Canonicalization and sign

`canonicalize_nan_bits` maps every raw NaN to positive quiet NaN `0x7ff8000000000000` (binary64) or `0x7fc00000` (binary32), leaving non-NaNs unchanged. `to_bits_canonical(x)` guarantees that exact integer encoding for numeric NaN. `canonicalize_nan(x)` returns a numeric quiet NaN; subsequent host storage may change its representation, so use `to_bits_canonical` at serialization boundaries.

`copy_sign_bits`, `negate_bits` and `abs_bits` alter only the sign bit, preserving every other bit, including NaN payload and signaling state. Portable numeric `portable_copy_sign`, `portable_negate` and `portable_abs` canonicalize NaN; all non-NaN encodings, including infinities and signed zero, undergo exact sign transformations. A numeric NaN sign donor is treated conservatively rather than exposing its host sign.

## Payload encoding adapters

`get_payload_bits(bits)` returns `None` for non-NaN and `Some(payload)` for NaN, excluding the quiet bit. `set_payload_bits(payload, sign_minus?=false)` returns a quiet-NaN encoding or `None` when the payload exceeds 51 bits (binary64) or 22 bits (binary32). `set_payload_signaling_bits` also rejects zero payload, which would encode infinity. These functions accept and return integer encodings; they adapt IEEE 754-2019 §9.7 rather than exposing the standard floating-point getPayload/setPayload functions directly.

The `portable_*` names describe this application NaN-normalized view, not IEEE sign/classification operations on the original NaN. Use `classify_bits`, `is_signaling_bits`, `is_sign_minus_bits` and raw sign operations when IEEE encoding semantics are required. `is_canonical_bits` tests IEEE canonical encoding, not equality with the application's fixed NaN pattern.
