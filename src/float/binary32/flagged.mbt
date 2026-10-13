///|
/// convertFormat from binary32 to binary64 on a raw encoding with its flags: the conversion is
/// exact, so only a signaling NaN raises invalid (and becomes quiet).
pub fn to_binary64_bits_flags(bits : UInt32) -> (UInt64, @binary64.Flags) {
  (
    to_binary64_bits(bits),
    { ..@binary64.Flags::none(), invalid: is_signaling_bits(bits), },
  )
}

///|
/// nextUp on a raw binary32 encoding with its flags: invalid only for a signaling NaN.
pub fn next_up_bits_flags(bits : UInt32) -> (UInt32, @binary64.Flags) {
  (
    next_up_bits(bits),
    { ..@binary64.Flags::none(), invalid: is_signaling_bits(bits), },
  )
}

///|
/// nextDown on a raw binary32 encoding with its flags: invalid only for a signaling NaN.
pub fn next_down_bits_flags(bits : UInt32) -> (UInt32, @binary64.Flags) {
  (
    next_down_bits(bits),
    { ..@binary64.Flags::none(), invalid: is_signaling_bits(bits), },
  )
}

///|
/// remainder on raw binary32 encodings with its flags; see `@float.remainder_bits_flags`.
pub fn remainder_bits_flags(
  x : UInt32,
  y : UInt32,
) -> (UInt32, @binary64.Flags) {
  let invalid = is_signaling_bits(x) ||
    is_signaling_bits(y) ||
    (
      !is_nan_bits(x) &&
      !is_nan_bits(y) &&
      (is_infinite_bits(x) || is_zero_bits(y))
    )
  (remainder_bits(x, y), { ..@binary64.Flags::none(), invalid, })
}

///|
/// logB as an integer with its flags: `None` with invalid for NaN, infinities and zeros.
pub fn logb_bits_flags(bits : UInt32) -> (Int32?, @binary64.Flags) {
  match logb_bits(bits) {
    Some(e) => (Some(e), @binary64.Flags::none())
    None => (None, @binary64.Flags::invalid_only())
  }
}

///|
/// logB of a portable binary32 value with a floating-point result and its flags: `logB(0)` is
/// `-inf` with divideByZero.
pub fn logb_flags(x : Float) -> (Float, @binary64.Flags) {
  if x == 0.0F {
    (-1.0F / 0.0F, { ..@binary64.Flags::none(), divide_by_zero: true, })
  } else {
    (logb(x), @binary64.Flags::none())
  }
}

///|
/// roundToIntegral on a raw binary32 encoding with its flags; see
/// `@float.round_to_integral_bits_flags`.
pub fn round_to_integral_bits_flags(
  bits : UInt32,
  direction : @binary64.RoundingDirection,
  exact~ : Bool = false,
) -> (UInt32, @binary64.Flags) {
  if is_nan_bits(bits) {
    (
      nanq_bits(bits),
      { ..@binary64.Flags::none(), invalid: is_signaling_bits(bits), },
    )
  } else {
    let r = round_bits(bits, direction)
    (r, { ..@binary64.Flags::none(), inexact: exact && r != bits, })
  }
}

///|
/// convertToInteger to `Int` with its flags; see `@float.to_int_flags`.
pub fn to_int_flags(
  x : Float,
  direction : @binary64.RoundingDirection,
  exact~ : Bool = false,
) -> (Int32?, @binary64.Flags) {
  @binary64.to_int_flags(x.to_double(), direction, exact~)
}

///|
/// convertToInteger to `Int64` with its flags.
pub fn to_int64_flags(
  x : Float,
  direction : @binary64.RoundingDirection,
  exact~ : Bool = false,
) -> (Int64?, @binary64.Flags) {
  @binary64.to_int64_flags(x.to_double(), direction, exact~)
}

///|
/// convertToInteger to `UInt` with its flags.
pub fn to_uint_flags(
  x : Float,
  direction : @binary64.RoundingDirection,
  exact~ : Bool = false,
) -> (UInt32?, @binary64.Flags) {
  @binary64.to_uint_flags(x.to_double(), direction, exact~)
}

///|
/// convertToInteger to `UInt64` with its flags.
pub fn to_uint64_flags(
  x : Float,
  direction : @binary64.RoundingDirection,
  exact~ : Bool = false,
) -> (UInt64?, @binary64.Flags) {
  @binary64.to_uint64_flags(x.to_double(), direction, exact~)
}
