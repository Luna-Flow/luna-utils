///|
/// Convert the binary32 value `x` to `Int`, rounding toward zero (truncation)
/// first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[-2147483648, 2147483647]`. The range decision is made after
/// rounding, not on `x` itself; both zeros convert to `Some(0)`. For example
/// `2147483647.5` rounds toward zero to `2147483647` and yields
/// `Some(2147483647)`, while `2147483648.0` yields `None`. A binary32 value
/// converts exactly to binary64 first, so the contract is identical to the
/// `Double` function in `@float`.
pub fn to_int_checked(x : Float) -> Int32? {
  @binary64.to_int_checked(x.to_double())
}

///|
/// Convert the binary32 value `x` to `Int`, rounding in the given `direction`
/// (one of the five IEEE 754-2019 §5.9 directions) first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[-2147483648, 2147483647]`. The range decision is made after
/// rounding, not on `x` itself; both zeros convert to `Some(0)`. For example
/// `2147483647.5` rounds, with `TowardZero`, to `2147483647` and yields
/// `Some(2147483647)`, while `2147483648.0` yields `None`. A binary32 value
/// converts exactly to binary64 first, so the contract is identical to the
/// `Double` function in `@float`.
pub fn to_int_checked_with(
  x : Float,
  direction : @binary64.RoundingDirection,
) -> Int32? {
  @binary64.to_int_checked_with(x.to_double(), direction)
}

///|
/// Convert the binary32 value `x` to `Int`, rounding toward zero (truncation)
/// first and saturating like WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[-2147483648, 2147483647]`. The
/// decision is made after rounding; both zeros convert to `0`. A binary32 value
/// converts exactly to binary64 first, so the contract is identical to the
/// `Double` function in `@float`.
pub fn to_int_saturating(x : Float) -> Int32 {
  @binary64.to_int_saturating(x.to_double())
}

///|
/// Convert the binary32 value `x` to `Int`, rounding in the given `direction`
/// (one of the five IEEE 754-2019 §5.9 directions) first and saturating like
/// WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[-2147483648, 2147483647]`. The
/// decision is made after rounding; both zeros convert to `0`. A binary32 value
/// converts exactly to binary64 first, so the contract is identical to the
/// `Double` function in `@float`.
pub fn to_int_saturating_with(
  x : Float,
  direction : @binary64.RoundingDirection,
) -> Int32 {
  @binary64.to_int_saturating_with(x.to_double(), direction)
}

///|
/// Convert the binary32 value `x` to `Int64`, rounding toward zero (truncation)
/// first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[-9223372036854775808, 9223372036854775807]`. The range decision is
/// made after rounding, not on `x` itself; both zeros convert to `Some(0)`. For
/// example `-9223372036854775808.0` is exactly the minimum and yields `Some`,
/// while `9223372036854775808.0` yields `None`. A binary32 value converts
/// exactly to binary64 first, so the contract is identical to the `Double`
/// function in `@float`.
pub fn to_int64_checked(x : Float) -> Int64? {
  @binary64.to_int64_checked(x.to_double())
}

///|
/// Convert the binary32 value `x` to `Int64`, rounding in the given `direction`
/// (one of the five IEEE 754-2019 §5.9 directions) first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[-9223372036854775808, 9223372036854775807]`. The range decision is
/// made after rounding, not on `x` itself; both zeros convert to `Some(0)`. For
/// example `-9223372036854775808.0` is exactly the minimum and yields `Some`,
/// while `9223372036854775808.0` yields `None`. A binary32 value converts
/// exactly to binary64 first, so the contract is identical to the `Double`
/// function in `@float`.
pub fn to_int64_checked_with(
  x : Float,
  direction : @binary64.RoundingDirection,
) -> Int64? {
  @binary64.to_int64_checked_with(x.to_double(), direction)
}

///|
/// Convert the binary32 value `x` to `Int64`, rounding toward zero (truncation)
/// first and saturating like WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[-9223372036854775808,
/// 9223372036854775807]`. The decision is made after rounding; both zeros
/// convert to `0`. A binary32 value converts exactly to binary64 first, so the
/// contract is identical to the `Double` function in `@float`.
pub fn to_int64_saturating(x : Float) -> Int64 {
  @binary64.to_int64_saturating(x.to_double())
}

///|
/// Convert the binary32 value `x` to `Int64`, rounding in the given `direction`
/// (one of the five IEEE 754-2019 §5.9 directions) first and saturating like
/// WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[-9223372036854775808,
/// 9223372036854775807]`. The decision is made after rounding; both zeros
/// convert to `0`. A binary32 value converts exactly to binary64 first, so the
/// contract is identical to the `Double` function in `@float`.
pub fn to_int64_saturating_with(
  x : Float,
  direction : @binary64.RoundingDirection,
) -> Int64 {
  @binary64.to_int64_saturating_with(x.to_double(), direction)
}

///|
/// Convert the binary32 value `x` to `UInt`, rounding toward zero (truncation)
/// first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[0, 4294967295]`. The range decision is made after rounding, not on
/// `x` itself; both zeros convert to `Some(0)`. For example `-0.5` rounds
/// toward zero to `0` and yields `Some(0)`, while `-1.0` yields `None`. A
/// binary32 value converts exactly to binary64 first, so the contract is
/// identical to the `Double` function in `@float`.
pub fn to_uint_checked(x : Float) -> UInt32? {
  @binary64.to_uint_checked(x.to_double())
}

///|
/// Convert the binary32 value `x` to `UInt`, rounding in the given `direction`
/// (one of the five IEEE 754-2019 §5.9 directions) first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[0, 4294967295]`. The range decision is made after rounding, not on
/// `x` itself; both zeros convert to `Some(0)`. For example `-0.5` rounds, with
/// `TowardZero`, to `0` and yields `Some(0)`, while `-1.0` yields `None`. A
/// binary32 value converts exactly to binary64 first, so the contract is
/// identical to the `Double` function in `@float`.
pub fn to_uint_checked_with(
  x : Float,
  direction : @binary64.RoundingDirection,
) -> UInt32? {
  @binary64.to_uint_checked_with(x.to_double(), direction)
}

///|
/// Convert the binary32 value `x` to `UInt`, rounding toward zero (truncation)
/// first and saturating like WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[0, 4294967295]`. The decision
/// is made after rounding; both zeros convert to `0`. A binary32 value converts
/// exactly to binary64 first, so the contract is identical to the `Double`
/// function in `@float`.
pub fn to_uint_saturating(x : Float) -> UInt32 {
  @binary64.to_uint_saturating(x.to_double())
}

///|
/// Convert the binary32 value `x` to `UInt`, rounding in the given `direction`
/// (one of the five IEEE 754-2019 §5.9 directions) first and saturating like
/// WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[0, 4294967295]`. The decision
/// is made after rounding; both zeros convert to `0`. A binary32 value converts
/// exactly to binary64 first, so the contract is identical to the `Double`
/// function in `@float`.
pub fn to_uint_saturating_with(
  x : Float,
  direction : @binary64.RoundingDirection,
) -> UInt32 {
  @binary64.to_uint_saturating_with(x.to_double(), direction)
}

///|
/// Convert the binary32 value `x` to `UInt64`, rounding toward zero
/// (truncation) first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[0, 18446744073709551615]`. The range decision is made after
/// rounding, not on `x` itself; both zeros convert to `Some(0)`. For example
/// `-0.5` rounds toward zero to `0` and yields `Some(0)`, while
/// `18446744073709551616.0` yields `None`. A binary32 value converts exactly to
/// binary64 first, so the contract is identical to the `Double` function in
/// `@float`.
pub fn to_uint64_checked(x : Float) -> UInt64? {
  @binary64.to_uint64_checked(x.to_double())
}

///|
/// Convert the binary32 value `x` to `UInt64`, rounding in the given
/// `direction` (one of the five IEEE 754-2019 §5.9 directions) first.
///
/// Returns `None` for NaN, for infinities, and when the rounded integer lies
/// outside `[0, 18446744073709551615]`. The range decision is made after
/// rounding, not on `x` itself; both zeros convert to `Some(0)`. For example
/// `-0.5` rounds, with `TowardZero`, to `0` and yields `Some(0)`, while
/// `18446744073709551616.0` yields `None`. A binary32 value converts exactly to
/// binary64 first, so the contract is identical to the `Double` function in
/// `@float`.
pub fn to_uint64_checked_with(
  x : Float,
  direction : @binary64.RoundingDirection,
) -> UInt64? {
  @binary64.to_uint64_checked_with(x.to_double(), direction)
}

///|
/// Convert the binary32 value `x` to `UInt64`, rounding toward zero
/// (truncation) first and saturating like WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[0, 18446744073709551615]`. The
/// decision is made after rounding; both zeros convert to `0`. A binary32 value
/// converts exactly to binary64 first, so the contract is identical to the
/// `Double` function in `@float`.
pub fn to_uint64_saturating(x : Float) -> UInt64 {
  @binary64.to_uint64_saturating(x.to_double())
}

///|
/// Convert the binary32 value `x` to `UInt64`, rounding in the given
/// `direction` (one of the five IEEE 754-2019 §5.9 directions) first and
/// saturating like WebAssembly `trunc_sat`.
///
/// NaN converts to `0`, and an out-of-range rounded integer (including an
/// infinity) converts to the nearest bound of `[0, 18446744073709551615]`. The
/// decision is made after rounding; both zeros convert to `0`. A binary32 value
/// converts exactly to binary64 first, so the contract is identical to the
/// `Double` function in `@float`.
pub fn to_uint64_saturating_with(
  x : Float,
  direction : @binary64.RoundingDirection,
) -> UInt64 {
  @binary64.to_uint64_saturating_with(x.to_double(), direction)
}
