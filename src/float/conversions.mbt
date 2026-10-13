// Checked and saturating conversions from binary64 values.
//
// The range checks use half-open mathematical intervals on the rounded integer.
// They run before any core conversion primitive, whose behavior for an
// out-of-range value is backend-specific.

///|
/// Round `x` to an integral value in the given direction (NaN and infinities
/// are unchanged); the shared first step of every integer conversion below.
fn rounded(x : Double, direction : RoundingDirection) -> Double {
  round_to_integral(x, direction)
}

///|
fn int_checked_rounded(x : Double, direction : RoundingDirection) -> Int32? {
  let y = rounded(x, direction)
  if y != y || y >= 2147483648.0 || y < -2147483648.0 {
    None
  } else {
    Some(y.to_int())
  }
}

///|
fn int64_checked_rounded(x : Double, direction : RoundingDirection) -> Int64? {
  let y = rounded(x, direction)
  if y != y || y >= 9223372036854775808.0 || y < -9223372036854775808.0 {
    None
  } else {
    Some(y.to_int64())
  }
}

///|
fn uint_checked_rounded(x : Double, direction : RoundingDirection) -> UInt32? {
  let y = rounded(x, direction)
  if y != y || y < 0.0 || y >= 4294967296.0 {
    None
  } else {
    Some(y.to_uint())
  }
}

///|
fn uint64_checked_rounded(x : Double, direction : RoundingDirection) -> UInt64? {
  let y = rounded(x, direction)
  if y != y || y < 0.0 || y >= 18446744073709551616.0 {
    None
  } else if y < 9223372036854775808.0 {
    Some(y.to_int64().reinterpret_as_uint64())
  } else {
    let low = (y - 9223372036854775808.0).to_int64().reinterpret_as_uint64()
    Some(0x8000000000000000UL | low)
  }
}

///|
/// Convert the binary64 value `x` to `Int`, rounding toward zero (truncation)
/// first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[-2147483648, 2147483647]`. The range decision is made after
/// rounding, not on `x` itself; both zeros convert to `Some(0)`. For example
/// `2147483647.5` rounds toward zero to `2147483647` and yields
/// `Some(2147483647)`, while `2147483648.0` yields `None`.
pub fn to_int_checked(x : Double) -> Int32? {
  int_checked_rounded(x, TowardZero)
}

///|
/// Convert the binary64 value `x` to `Int`, rounding in the given `direction`
/// (one of the five IEEE 754-2019 §5.9 directions) first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[-2147483648, 2147483647]`. The range decision is made after
/// rounding, not on `x` itself; both zeros convert to `Some(0)`. For example,
/// with `TowardZero`, `2147483647.5` rounds to `2147483647` and yields
/// `Some(2147483647)`, while `2147483648.0` yields `None`.
pub fn to_int_checked_with(x : Double, direction : RoundingDirection) -> Int32? {
  int_checked_rounded(x, direction)
}

///|
/// Convert the binary64 value `x` to `Int`, rounding toward zero (truncation)
/// first and saturating like WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[-2147483648, 2147483647]`. The
/// decision is made after rounding; both zeros convert to `0`.
pub fn to_int_saturating(x : Double) -> Int32 {
  to_int_saturating_with(x, TowardZero)
}

///|
/// Convert the binary64 value `x` to `Int`, rounding in the given `direction`
/// (one of the five IEEE 754-2019 §5.9 directions) first and saturating like
/// WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[-2147483648, 2147483647]`. The
/// decision is made after rounding; both zeros convert to `0`.
pub fn to_int_saturating_with(
  x : Double,
  direction : RoundingDirection,
) -> Int32 {
  let y = rounded(x, direction)
  if y != y {
    0
  } else if y <= -2147483648.0 {
    -2147483648
  } else if y >= 2147483648.0 {
    2147483647
  } else {
    y.to_int()
  }
}

///|
/// Convert the binary64 value `x` to `Int64`, rounding toward zero (truncation)
/// first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[-9223372036854775808, 9223372036854775807]`. The range decision is
/// made after rounding, not on `x` itself; both zeros convert to `Some(0)`. For
/// example `-9223372036854775808.0` is exactly the minimum and yields `Some`,
/// while `9223372036854775808.0` yields `None`.
pub fn to_int64_checked(x : Double) -> Int64? {
  int64_checked_rounded(x, TowardZero)
}

///|
/// Convert the binary64 value `x` to `Int64`, rounding in the given `direction`
/// (one of the five IEEE 754-2019 §5.9 directions) first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[-9223372036854775808, 9223372036854775807]`. The range decision is
/// made after rounding, not on `x` itself; both zeros convert to `Some(0)`. For
/// example `-9223372036854775808.0` is exactly the minimum and yields `Some`,
/// while `9223372036854775808.0` yields `None`.
pub fn to_int64_checked_with(
  x : Double,
  direction : RoundingDirection,
) -> Int64? {
  int64_checked_rounded(x, direction)
}

///|
/// Convert the binary64 value `x` to `Int64`, rounding toward zero (truncation)
/// first and saturating like WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[-9223372036854775808,
/// 9223372036854775807]`. The decision is made after rounding; both zeros
/// convert to `0`.
pub fn to_int64_saturating(x : Double) -> Int64 {
  to_int64_saturating_with(x, TowardZero)
}

///|
/// Convert the binary64 value `x` to `Int64`, rounding in the given `direction`
/// (one of the five IEEE 754-2019 §5.9 directions) first and saturating like
/// WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[-9223372036854775808,
/// 9223372036854775807]`. The decision is made after rounding; both zeros
/// convert to `0`.
pub fn to_int64_saturating_with(
  x : Double,
  direction : RoundingDirection,
) -> Int64 {
  let y = rounded(x, direction)
  if y != y {
    0L
  } else if y <= -9223372036854775808.0 {
    -9223372036854775808L
  } else if y >= 9223372036854775808.0 {
    9223372036854775807L
  } else {
    y.to_int64()
  }
}

///|
/// Convert the binary64 value `x` to `UInt`, rounding toward zero (truncation)
/// first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[0, 4294967295]`. The range decision is made after rounding, not on
/// `x` itself; both zeros convert to `Some(0)`. For example `-0.5` rounds
/// toward zero to `0` and yields `Some(0)`, while `-1.0` yields `None`.
pub fn to_uint_checked(x : Double) -> UInt32? {
  uint_checked_rounded(x, TowardZero)
}

///|
/// Convert the binary64 value `x` to `UInt`, rounding in the given `direction`
/// (one of the five IEEE 754-2019 §5.9 directions) first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[0, 4294967295]`. The range decision is made after rounding, not on
/// `x` itself; both zeros convert to `Some(0)`. For example, with `TowardZero`,
/// `-0.5` rounds to `0` and yields `Some(0)`, while `-1.0` yields `None`.
pub fn to_uint_checked_with(
  x : Double,
  direction : RoundingDirection,
) -> UInt32? {
  uint_checked_rounded(x, direction)
}

///|
/// Convert the binary64 value `x` to `UInt`, rounding toward zero (truncation)
/// first and saturating like WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[0, 4294967295]`. The decision
/// is made after rounding; both zeros convert to `0`.
pub fn to_uint_saturating(x : Double) -> UInt32 {
  to_uint_saturating_with(x, TowardZero)
}

///|
/// Convert the binary64 value `x` to `UInt`, rounding in the given `direction`
/// (one of the five IEEE 754-2019 §5.9 directions) first and saturating like
/// WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[0, 4294967295]`. The decision
/// is made after rounding; both zeros convert to `0`.
pub fn to_uint_saturating_with(
  x : Double,
  direction : RoundingDirection,
) -> UInt32 {
  let y = rounded(x, direction)
  if y != y {
    0U
  } else if y <= 0.0 {
    0U
  } else if y >= 4294967296.0 {
    4294967295U
  } else {
    y.to_uint()
  }
}

///|
/// Convert the binary64 value `x` to `UInt64`, rounding toward zero
/// (truncation) first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[0, 18446744073709551615]`. The range decision is made after
/// rounding, not on `x` itself; both zeros convert to `Some(0)`. For example
/// `-0.5` rounds toward zero to `0` and yields `Some(0)`, while
/// `18446744073709551616.0` yields `None`.
pub fn to_uint64_checked(x : Double) -> UInt64? {
  uint64_checked_rounded(x, TowardZero)
}

///|
/// Convert the binary64 value `x` to `UInt64`, rounding in the given
/// `direction` (one of the five IEEE 754-2019 §5.9 directions) first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[0, 18446744073709551615]`. The range decision is made after
/// rounding, not on `x` itself; both zeros convert to `Some(0)`. For example,
/// with `TowardZero`, `-0.5` rounds to `0` and yields `Some(0)`, while
/// `18446744073709551616.0` yields `None`.
pub fn to_uint64_checked_with(
  x : Double,
  direction : RoundingDirection,
) -> UInt64? {
  uint64_checked_rounded(x, direction)
}

///|
/// Convert the binary64 value `x` to `UInt64`, rounding toward zero
/// (truncation) first and saturating like WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[0, 18446744073709551615]`. The
/// decision is made after rounding; both zeros convert to `0`.
pub fn to_uint64_saturating(x : Double) -> UInt64 {
  to_uint64_saturating_with(x, TowardZero)
}

///|
/// Convert the binary64 value `x` to `UInt64`, rounding in the given
/// `direction` (one of the five IEEE 754-2019 §5.9 directions) first and
/// saturating like WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[0, 18446744073709551615]`. The
/// decision is made after rounding; both zeros convert to `0`.
pub fn to_uint64_saturating_with(
  x : Double,
  direction : RoundingDirection,
) -> UInt64 {
  let y = rounded(x, direction)
  if y != y {
    0UL
  } else if y <= 0.0 {
    0UL
  } else if y >= 18446744073709551616.0 {
    0xffffffffffffffffUL
  } else {
    match uint64_checked_rounded(y, TowardZero) {
      Some(value) => value
      None => 0UL
    }
  }
}

///|
fn uint64_to_float_round_to_odd(magnitude : UInt64) -> Double {
  if magnitude == 0UL {
    0.0
  } else {
    let top = 63 - magnitude.clz()
    let shift = top - 52
    let significand : UInt64 = if shift <= 0 {
      magnitude << -shift
    } else {
      let kept = magnitude >> shift
      let remainder = magnitude & ((1UL << shift) - 1UL)
      if remainder != 0UL {
        kept | 1UL
      } else {
        kept
      }
    }
    let encoded_exponent = top + 1023
    let encoded_fraction = significand & 0xfffffffffffffUL
    ((encoded_exponent.to_uint64() << 52) | encoded_fraction).reinterpret_as_double()
  }
}

///|
/// Convert an `Int64` to the nearest binary32 `Float` (ties to even), rounding
/// the 64-bit integer exactly once.
///
/// This is the backend-independent counterpart of core `Float::from_int64`, which
/// follows each backend; on js it converts through binary64 first and so rounds twice (for
/// example `2^53 + 2^29 + 1` is rounded to the tie `2^53 + 2^29` and then to the
/// wrong neighbor `2^53`). It lives in `@float` because it uses the binary64 bit
/// helpers of this package, and returns a binary32 `Float`; the result is
/// bit-identical on every backend.
pub fn int64_to_float(value : Int64) -> Float {
  let raw = value.reinterpret_as_uint64()
  let negative = (raw & 0x8000000000000000UL) != 0UL
  let magnitude = if negative {
    (raw ^ 0xffffffffffffffffUL) + 1UL
  } else {
    raw
  }
  let intermediate = uint64_to_float_round_to_odd(magnitude)
  Float::from_double(if negative { -intermediate } else { intermediate })
}

///|
/// Convert a `UInt64` to the nearest binary32 `Float` (ties to even), rounding
/// the 64-bit integer exactly once.
///
/// This is the backend-independent counterpart of core `Float::from_uint64`, which
/// follows each backend; on js it converts through binary64 first and so rounds twice. See
/// `int64_to_float`; the result is bit-identical on every backend.
pub fn uint64_to_float(value : UInt64) -> Float {
  Float::from_double(uint64_to_float_round_to_odd(value))
}
