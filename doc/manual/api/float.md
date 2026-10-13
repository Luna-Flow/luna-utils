# Float classification and bit API

The package `Luna-Flow/luna-utils/float` operates on binary64 (`Double`, `UInt64` bits). `Luna-Flow/luna-utils/float/binary32` exposes the same function names for binary32 (`Float`, `UInt` bits) and shares the parent `Classification` enum. No host math or floating-point arithmetic is used by the raw-bit operations.

A raw integer encoding preserves NaN sign, signaling state and payload exactly. A numeric value does not preserve that information portably, especially on JavaScript. Numeric NaN is detected by `x != x`; `portable_classify` returns `QuietNaN` without inspecting its sign or payload. Keep signaling NaNs as integers when their representation matters.

## Classification and predicates

`classify_bits(bits)` distinguishes signaling NaN, quiet NaN, positive/negative infinity, normal, subnormal and zero. `portable_classify(x)` uses the same classes for non-NaN numbers and returns `QuietNaN` for every numeric NaN. `radix()` returns 2. The generated interfaces define the exact constructor names.

Predicates have raw `*_bits` and portable numeric forms. `is_signaling_bits` inspects the quiet bit; `portable_is_signaling` always returns `false` because signaling state is not portable. Binary interchange encodings are canonical, so both `is_canonical_bits` and `portable_is_canonical` always return `true`. For numeric NaN, sign-sensitive predicates must not infer a host sign. Consult the generated interface and conformance tests for the conservative numeric observations.

`is_infinite_bits` and `is_normal_bits` complete the §5.7.2 predicates on raw encodings; the numeric forms are `is_nan` (`x != x`), `is_infinite` and `is_normal` next to the existing `is_finite`, `is_subnormal` and `is_zero`.

## Comparison predicates

`Relation` has the four mutually exclusive relations of IEEE 754-2019 §5.11: `Less`, `Equal`, `Greater` and `Unordered`. `relation_bits(x, y)` works on raw encodings and `relation(x, y)` on numeric values: every NaN is unordered with everything including itself, `+0` and `-0` are equal, and infinities of the same sign are equal. `ComparisonPredicate` names the 22 predicates of §5.6.1 (Tables 5.1 and 5.2), from `QuietEqual` to `QuietOrdered`. Each is true for the relations its name lists, so `SignalingNotLess` is true for `Equal`, `Greater` and `Unordered`, and is not the logical negation of `SignalingGreaterEqual` when an operand is a NaN.

`compare_predicate_bits(predicate, x, y)` and `compare_predicate(predicate, x, y)` return `(value, invalid)`. `invalid` is true where the standard requires the invalid operation exception: for a signaling NaN operand with any predicate, and for a quiet NaN operand with a `Signaling` predicate. The numeric form cannot see signaling NaNs (the same limit as the rest of the package), so it reports `invalid` only for the `Signaling` predicates and a NaN operand. Until exception flags exist ([issue #29](https://github.com/Luna-Flow/luna-utils/issues/29)) the `Bool` is the only way the exception is reported. `predicate_outcome` is the evaluation step shared by `float` and `float/binary32`; use the two functions above instead. The `binary32` package has the same function names and shares the two enums with `float`.

## Canonicalization and sign

`canonicalize_nan_bits` maps every raw NaN to positive quiet NaN `0x7ff8000000000000` (binary64) or `0x7fc00000` (binary32), leaving non-NaNs unchanged. `to_bits_canonical(x)` guarantees that exact integer encoding for numeric NaN. `canonicalize_nan(x)` returns a numeric quiet NaN; subsequent host storage may change its representation, so use `to_bits_canonical` at serialization boundaries.

`copy_sign_bits`, `negate_bits` and `abs_bits` alter only the sign bit, preserving every other bit, including NaN payload and signaling state. Portable numeric `portable_copy_sign`, `portable_negate` and `portable_abs` canonicalize NaN; all non-NaN encodings, including infinities and signed zero, undergo exact sign transformations. A numeric NaN sign donor is treated conservatively rather than exposing its host sign.

## Rounding to integral values

`RoundingDirection` names the five IEEE 754-2019 §5.9 `roundToIntegral` directions: `TiesToEven`, `TiesToAway`, `TowardZero`, `TowardPositive` and `TowardNegative`. `round_to_integral(x, direction)` and the five named helpers (`round_ties_even`, `round_ties_away`, `round_toward_zero`, `round_toward_positive`, `round_toward_negative`) return an integral value in the same binary format. The binary32 package accepts the shared parent enum.

The implementation rounds directly from the sign, exponent and fraction fields. It preserves both zero signs and already integral values, returns positive canonical quiet NaN for NaN input (dropping NaN sign and payload), and leaves infinities unchanged. It does not report the invalid exception for sNaN input or the inexact flag for non-integral input; those reports are deferred to the `_exact` variant with the status-flag API in issue [#29](https://github.com/Luna-Flow/luna-utils/issues/29).

## Integer conversions

Both packages provide the same sixteen functions: `to_int_checked`, `to_int64_checked`, `to_uint_checked`, `to_uint64_checked`, the four `*_saturating` counterparts, and a `_with` form of each that takes a `RoundingDirection`. `@float` converts `Double`; `@binary32` converts `Float` and widens it exactly to binary64 first, so both packages follow one contract. The targets are `Int` (`[-2^31, 2^31 - 1]`), `Int64` (`[-2^63, 2^63 - 1]`), `UInt` (`[0, 2^32 - 1]`) and `UInt64` (`[0, 2^64 - 1]`).

The value is first rounded to an integer with the chosen direction; the functions without `_with` round toward zero (truncation). The range decision is made on that rounded integer, after rounding, and never on the input. Hence `-0.5` converts to `Some(0)` for `to_uint_checked` (it truncates to zero) but to `None` with `TowardNegative` (it rounds to `-1`), and `2147483647.5` fits `Int` when truncated but not when rounded `TiesToEven`. Both zeros, `+0` and `-0`, convert to `0`.

`*_checked` returns `None` for NaN, for `+inf` and `-inf`, and when the rounded integer is outside the target range; otherwise `Some(n)`. `*_saturating` clamps like WebAssembly `trunc_sat`: NaN converts to `0`, `+inf` and any rounded value above the range convert to the largest value of the target, and `-inf` and any value below the range convert to its smallest (`0` for the unsigned targets). The range tests run on the rounded `Double` before any core conversion primitive is called, because core's behavior for out-of-range values differs between backends.

`int64_to_float(Int64) -> Float` and `uint64_to_float(UInt64) -> Float` are in `@float` but return a binary32 `Float`: the result is the 64-bit integer rounded once to the nearest binary32 value, ties to even. They are the backend-independent counterpart of core's `Float::from_int64` and `Float::from_uint64`, which follow each backend's own conversion (on the JavaScript backend through binary64 first, so they round twice, by design of core); for example `2^53 + 2^29 + 1` is rounded to the tie `2^53 + 2^29` by the first rounding and then to the wrong binary32 neighbor `2^53`. The implementation rounds to an odd intermediate significand, so the results are bit-identical on every backend. The placement of these two functions (`@float` or `@binary32`) is an open question for the maintainer.

## Extrema and ordering

`minimum(x, y)` and `maximum(x, y)` implement IEEE 754-2019 §9.6 for binary64; the binary32 package exposes the same names. Either NaN input produces positive canonical quiet NaN; NaN sign and payload are not propagated. For zero operands, minimum selects `-0` if either operand is negative zero, while maximum selects `+0` if either operand is positive zero. These value functions do not report the invalid exception for sNaN; exception flags are not part of this package's API, and signaling behavior is deferred to issue [#29](https://github.com/Luna-Flow/luna-utils/issues/29).

The remaining §9.6 operations are `minimum_number` and `maximum_number` (the number when exactly one operand is a NaN, the canonical quiet NaN when both are), `minimum_magnitude` and `maximum_magnitude` (the operand of smaller or larger absolute value, otherwise `minimum` or `maximum`) and `minimum_magnitude_number` and `maximum_magnitude_number` (the same with the `Number` rule). A numeric value cannot tell a signaling NaN from a quiet one, so these functions do not report the invalid operation that the standard requires for a signaling NaN operand.

`total_order_mag_bits(x, y)` is §5.10 totalOrderMag on raw encodings, that is totalOrder of the absolute values, and `portable_total_order_mag(x, y)` is the numeric form.

`portable_total_order(x, y)` implements §5.10 over portable numeric values. `total_order_bits(x, y)` implements the full encoding order from integer bits, preserving NaN sign, signaling state and payload. This distinction is required because numeric NaN representation is not portable, especially on JavaScript. `sort_total_order(values)` sorts a mutable array, and `sort_total_order_view(view)` sorts a mutable array view, using the portable value order. All normalized NaNs compare after numbers, but core `sort_by` is unstable: equal normalized keys may reorder, original NaN bits are retained, and JavaScript may canonicalize their payloads. Negative NaNs therefore do not acquire raw IEEE totalOrder placement. Exact NaN encoding order is available only through `total_order_bits` on raw integer encodings.

## Payload encoding adapters

`get_payload_bits(bits)` returns `None` for non-NaN and `Some(payload)` for NaN, excluding the quiet bit. `set_payload_bits(payload, sign_minus?=false)` returns a quiet-NaN encoding or `None` when the payload exceeds 51 bits (binary64) or 22 bits (binary32). `set_payload_signaling_bits` also rejects zero payload, which would encode infinity. These functions accept and return integer encodings; they adapt IEEE 754-2019 §9.7 rather than exposing the standard floating-point getPayload/setPayload functions directly.

The `portable_*` names describe this application NaN-normalized view, not IEEE sign/classification operations on the original NaN. Use `classify_bits`, `is_signaling_bits`, `is_sign_minus_bits` and raw sign operations when IEEE encoding semantics are required. `is_canonical_bits` tests IEEE canonical encoding, not equality with the application's fixed NaN pattern.

## Remainder, nextUp, nextDown, scaleB and logB

All of these work on the integer fields, with no host arithmetic, so they are identical on every backend. Each has a raw form on encodings (`*_bits`) that keeps NaN payloads and a numeric form that returns the canonical quiet NaN for every NaN.

`next_up_bits` and `next_down_bits` (numeric `next_up`, `next_down`) are IEEE 754-2019 §5.3.1 nextUp and nextDown: the neighbouring value in the format, `nextUp(-0)` and `nextUp(+0)` are the smallest positive value, the successor of the negative value of least magnitude is `-0`, and `nextUp(+inf)` is `+inf`. A NaN becomes quiet and keeps its sign and payload in the raw form.

`remainder_bits(x, y)` and `remainder(x, y)` are the IEEE remainder `x - y * n` with `n` the integer nearest `x / y`, ties to even. The result is exact for every finite operand, a zero result has the sign of `x`, `remainder(x, inf)` is `x`, and an infinite `x` or a zero `y` gives the canonical quiet NaN. The invalid operation exception is not reported until exception flags exist ([issue #29](https://github.com/Luna-Flow/luna-utils/issues/29)).

`scaleb_bits_with(bits, n, direction)` and `scaleb_with(x, n, direction)` compute `x * 2^n` rounded once to the format by the given `RoundingDirection`, with gradual underflow and the overflow rule of each direction; `scaleb_bits` and `scaleb` use ties to even. Zeros, infinities and `n = 0` return `x`, and `n` may be any `Int`. `logb_bits(bits)` returns the exponent `floor(log2 |x|)` as an `Int?` computed as though the range were unbounded (a subnormal gives its true exponent), and `None` for NaN, infinities and zeros, which the standard calls exceptional. `logb(x)` is the floating-point form: `logB(NaN)` is a NaN, `logB(inf)` is `+inf` and `logB(0)` is `-inf`.

## Conversion between binary64 and binary32

`to_binary32_bits_with(bits, direction)` and `to_binary32_with(x, direction)` are IEEE 754-2019 §5.4.2 convertFormat from binary64 to binary32: the value is rounded once by the given `RoundingDirection`, with gradual underflow and the overflow rule of the direction (infinity or the largest finite value); `to_binary32_bits` and `to_binary32` use ties to even. Zeros and infinities keep their sign. In `float/binary32`, `to_binary64_bits(bits)` and `to_binary64(x)` widen exactly.

For NaNs the raw forms follow §6.2.3: the result is quiet, keeps the sign, and carries the payload bits that fit (the high 22 payload bits when narrowing, shifted up when widening), so widening a quiet NaN and narrowing it back changes nothing. The numeric forms return the canonical quiet NaN. The invalid operation exception for a signaling NaN is not reported until exception flags exist ([issue #29](https://github.com/Luna-Flow/luna-utils/issues/29)). The randomized audit also checks core's `Float::from_double` and `Float::to_double` against the same model and finds them correct on every backend, so they are safe for values; they do not give directed rounding or a defined NaN payload.

## Fused multiply-add

`fma_bits_with(x, y, z, direction)` and `fma_with(x, y, z, direction)` are IEEE 754-2019 §5.3.1 fusedMultiplyAdd: `x * y + z` computed exactly and rounded once by the given `RoundingDirection`, with gradual underflow and the overflow rule of the direction; `fma_bits` and `fma` use ties to even. The `float/binary32` package has the same names for binary32, rounding once at binary32 precision (not through binary64). The implementation is pure integer arithmetic on the encodings (a 128-bit window with a sticky bit), so it is identical on every backend and does not depend on a host fma.

Special values: a NaN operand gives a quiet NaN that keeps its sign and payload (the first of `x`, `y`, `z`); `inf * 0` and `inf + (-inf)` give the canonical quiet NaN; an infinite product or addend gives the infinity; the sign of an exact zero result is the common sign when the product and the addend are both zero of the same sign, and otherwise `+0` (`-0` for `TowardNegative`). Numeric forms return the canonical quiet NaN. The invalid operation, overflow, underflow and inexact exceptions are not reported until exception flags exist ([issue #29](https://github.com/Luna-Flow/luna-utils/issues/29)). `fma_finite_bits` is the engine shared by both formats; use the functions above.

## Error-free transformations

`two_sum(a, b)` (Knuth's TwoSum) returns `(s, e)` with `s = a + b` rounded to nearest even and `e` the rounding error, so that `a + b == s + e` exactly whenever `a`, `b` and `s` are finite; it needs no assumption on the order of the operands. `fast_two_sum(a, b)` (Dekker's Fast2Sum) gives the same result with fewer operations when `|a| >= |b|` or `a == 0`; the result is unspecified otherwise. `two_prod(a, b)` returns `(p, e)` with `p = a * b` rounded to nearest even and `e = fma(a, b, -p)`; `a * b == p + e` exactly when the error is representable, which holds when the exponents of `a` and `b` add up to at least `emin + precision - 1` (`-969` for binary64, `-103` for binary32), and below that the error is rounded once. When `s` or `p` is not finite, because of an infinite or NaN operand or an overflow, `e` is the quiet NaN. A zero error is `+0`. All three exist for `Double` in `float` and for `Float` in `float/binary32`, and they are not IEEE 754 operations: the §9.5 augmented arithmetic is a different, still missing, operation.

## Exception flags

`Flags` has the five exception flags of IEEE 754-2019 §7: `invalid`, `divide_by_zero`, `overflow`, `underflow` and `inexact`. The package keeps no global status word: an operation with a `_flags` suffix returns `(value, Flags)` and the caller combines the sets with `Flags::combine`; `Flags::none()` is the empty set, `Flags::is_empty` tests it and `Flags::to_bits` gives the layout of Berkeley TestFloat (inexact 1, underflow 2, overflow 4, divide by zero 8, invalid 16). The flagged operations are `fma_bits_flags`, `remainder_bits_flags`, `next_up_bits_flags` and `next_down_bits_flags`, `scaleb_bits_flags`, `logb_bits_flags` (the integer result, `None` with invalid for NaN, infinities and zeros) and `logb_flags` (the floating-point result, `-inf` with divideByZero for zero), `round_to_integral_bits_flags` (roundToIntegral, or roundToIntegralExact with `exact=true`), the four `to_*_flags` conversions to integers (convertToInteger, or the Exact variants with `exact=true`; `None` with invalid for NaN, infinities and out-of-range values) and `to_binary32_bits_flags` and, in `float/binary32`, `to_binary64_bits_flags`. The value of a `_flags` function is the value of the function without the suffix.

Overflow also raises inexact. Underflow is raised when the result is tiny and inexact, and tininess is detected after rounding: a result is tiny when the value rounded to the full precision with an unbounded exponent is below the smallest normal, so a value just below it that rounds up to the smallest normal is not tiny. Invalid is raised for a signaling NaN operand (only the raw forms can see one), for `inf * 0` and `inf - inf` in fma, for an infinite dividend or a zero divisor in remainder, and for a conversion to integer that has no result. A quiet NaN with `inf * 0` in fma raises nothing. The host operators `+ - * /` and `sqrt` and the numeric forms of the operations cannot report flags that the host did not record; the first have none until [issue #64](https://github.com/Luna-Flow/luna-utils/issues/64).

