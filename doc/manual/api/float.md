# Float classification and bit API

The package `Luna-Flow/luna-utils/float` operates on binary64 (`Double`, `UInt64` bits). `Luna-Flow/luna-utils/float/binary32` exposes the same function names for binary32 (`Float`, `UInt` bits) and shares the parent `Classification` enum. No host math or floating-point arithmetic is used by the raw-bit operations.

A raw integer encoding preserves NaN sign, signaling state and payload exactly. A numeric value does not preserve that information portably, especially on JavaScript. Numeric NaN is detected by `x != x`; `portable_classify` returns `QuietNaN` without inspecting its sign or payload. Keep signaling NaNs as integers when their representation matters.

## Classification and predicates

`classify_bits(bits)` distinguishes signaling NaN, quiet NaN, positive/negative infinity, normal, subnormal and zero. `portable_classify(x)` uses the same classes for non-NaN numbers and returns `QuietNaN` for every numeric NaN. `radix()` returns 2. The generated interfaces define the exact constructor names.

Predicates have raw `*_bits` and portable numeric forms. `is_signaling_bits` inspects the quiet bit; `portable_is_signaling` always returns `false` because signaling state is not portable. Binary interchange encodings are canonical, so both `is_canonical_bits` and `portable_is_canonical` always return `true`. For numeric NaN, sign-sensitive predicates must not infer a host sign. Consult the generated interface and conformance tests for the conservative numeric observations.

## Canonicalization and sign

`canonicalize_nan_bits` maps every raw NaN to positive quiet NaN `0x7ff8000000000000` (binary64) or `0x7fc00000` (binary32), leaving non-NaNs unchanged. `to_bits_canonical(x)` guarantees that exact integer encoding for numeric NaN. `canonicalize_nan(x)` returns a numeric quiet NaN; subsequent host storage may change its representation, so use `to_bits_canonical` at serialization boundaries.

`copy_sign_bits`, `negate_bits` and `abs_bits` alter only the sign bit, preserving every other bit, including NaN payload and signaling state. Portable numeric `portable_copy_sign`, `portable_negate` and `portable_abs` canonicalize NaN; all non-NaN encodings, including infinities and signed zero, undergo exact sign transformations. A numeric NaN sign donor is treated conservatively rather than exposing its host sign.

## Rounding to integral values

`RoundingDirection` names the five IEEE 754-2019 §5.9 `roundToIntegral` directions: `TiesToEven`, `TiesToAway`, `TowardZero`, `TowardPositive` and `TowardNegative`. `round_to_integral(x, direction)` and the five named helpers (`round_ties_even`, `round_ties_away`, `round_toward_zero`, `round_toward_positive`, `round_toward_negative`) return an integral value in the same binary format. The binary32 package accepts the shared parent enum.

The implementation rounds directly from the sign, exponent and fraction fields. It preserves both zero signs and already integral values, returns positive canonical quiet NaN for NaN input (dropping NaN sign and payload), and leaves infinities unchanged. It does not report the invalid exception for sNaN input or the inexact flag for non-integral input; those reports are deferred to the `_exact` variant with the status-flag API in issue [#29](https://github.com/Luna-Flow/luna-utils/issues/29).

## Extrema and ordering

`minimum(x, y)` and `maximum(x, y)` implement IEEE 754-2019 §9.6 for binary64; the binary32 package exposes the same names. Either NaN input produces positive canonical quiet NaN. For zero operands, minimum selects `-0` if either operand is negative zero, while maximum selects `+0` if either operand is positive zero. These value functions do not report the invalid exception for sNaN; exception flags are not part of this package's API.

`portable_total_order(x, y)` implements §5.10 over portable numeric values. `total_order_bits(x, y)` implements the full encoding order from integer bits, preserving NaN sign, signaling state and payload. This distinction is required because numeric NaN representation is not portable, especially on JavaScript. `sort_total_order(values)` sorts a mutable array, and `sort_total_order_view(view)` sorts a mutable array view, using the portable value order. The core `sort_by` operation is unstable: equal normalized keys may reorder, and original NaN bits are retained, so negative NaNs do not acquire raw IEEE totalOrder placement. Exact NaN encoding order is available only through `total_order_bits` on raw integer encodings.

## Payload encoding adapters

`get_payload_bits(bits)` returns `None` for non-NaN and `Some(payload)` for NaN, excluding the quiet bit. `set_payload_bits(payload, sign_minus?=false)` returns a quiet-NaN encoding or `None` when the payload exceeds 51 bits (binary64) or 22 bits (binary32). `set_payload_signaling_bits` also rejects zero payload, which would encode infinity. These functions accept and return integer encodings; they adapt IEEE 754-2019 §9.7 rather than exposing the standard floating-point getPayload/setPayload functions directly.

The `portable_*` names describe this application NaN-normalized view, not IEEE sign/classification operations on the original NaN. Use `classify_bits`, `is_signaling_bits`, `is_sign_minus_bits` and raw sign operations when IEEE encoding semantics are required. `is_canonical_bits` tests IEEE canonical encoding, not equality with the application's fixed NaN pattern.
