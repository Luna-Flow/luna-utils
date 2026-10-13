///|
/// The shared rounding engine of the flagged operations: round the exact value
/// `magnitude * 2^exponent` (with `magnitude` nonzero) to a format with `mbits` (52 or 23)
/// fraction bits by `direction` and report the flags of IEEE 754-2019 §7.3 to §7.6. The result
/// is an encoding of that format. `float/binary32` uses it; call the operations instead.
pub fn round_exact_flags(
  negative : Bool,
  magnitude : UInt64,
  exponent : Int32,
  mbits : Int32,
  direction : RoundingDirection,
) -> (UInt64, Flags) {
  round_pack_flags(
    negative,
    { hi: 0UL, lo: magnitude, },
    exponent,
    mbits,
    direction,
  )
}

///|
/// nextUp on a raw encoding with its flags: invalid only for a signaling NaN.
pub fn next_up_bits_flags(bits : UInt64) -> (UInt64, Flags) {
  (next_up_bits(bits), { ..Flags::none(), invalid: is_signaling_bits(bits), })
}

///|
/// nextDown on a raw encoding with its flags: invalid only for a signaling NaN.
pub fn next_down_bits_flags(bits : UInt64) -> (UInt64, Flags) {
  (next_down_bits(bits), { ..Flags::none(), invalid: is_signaling_bits(bits), })
}

///|
/// remainder on raw encodings with its flags: invalid for a signaling NaN, an infinite `x` and a
/// zero `y`; the result of a finite remainder is exact, so nothing else is raised.
pub fn remainder_bits_flags(x : UInt64, y : UInt64) -> (UInt64, Flags) {
  let invalid = is_signaling_bits(x) ||
    is_signaling_bits(y) ||
    (
      !is_nan_bits(x) &&
      !is_nan_bits(y) &&
      (is_infinite_bits(x) || is_zero_bits(y))
    )
  (remainder_bits(x, y), { ..Flags::none(), invalid, })
}

///|
/// logB as an integer with its flags: `None` for NaN, infinities and zeros, which the standard
/// declares exceptional, with the invalid operation flag raised.
pub fn logb_bits_flags(bits : UInt64) -> (Int32?, Flags) {
  match logb_bits(bits) {
    Some(e) => (Some(e), Flags::none())
    None => (None, Flags::invalid_only())
  }
}

///|
/// logB of a portable value with a floating-point result and its flags: `logB(0)` is `-inf`
/// with divideByZero, a NaN gives the quiet NaN, `logB(inf)` is `+inf`.
pub fn logb_flags(x : Double) -> (Double, Flags) {
  if x == 0.0 {
    (-1.0 / 0.0, { ..Flags::none(), divide_by_zero: true, })
  } else {
    (logb(x), Flags::none())
  }
}

///|
/// roundToIntegral on a raw encoding with its flags. A signaling NaN raises invalid and becomes
/// quiet. With `exact`, the result of roundToIntegralExact, inexact is raised when the rounded
/// value differs from the operand.
pub fn round_to_integral_bits_flags(
  bits : UInt64,
  direction : RoundingDirection,
  exact~ : Bool = false,
) -> (UInt64, Flags) {
  if is_nan_bits(bits) {
    (nanq_bits(bits), { ..Flags::none(), invalid: is_signaling_bits(bits), })
  } else {
    let r = round_bits(bits, direction)
    (r, { ..Flags::none(), inexact: exact && r != bits, })
  }
}

///|
/// convertToInteger to `Int` with its flags: `None` with invalid for NaN, infinities and values
/// outside the range after rounding; with `exact`, inexact when the rounded value differs.
pub fn to_int_flags(
  x : Double,
  direction : RoundingDirection,
  exact~ : Bool = false,
) -> (Int32?, Flags) {
  match int_checked_rounded(x, direction) {
    None => (None, Flags::invalid_only())
    Some(v) =>
      (
        Some(v),
        { ..Flags::none(), inexact: exact && rounded(x, direction) != x, },
      )
  }
}

///|
/// convertToInteger to `Int64` with its flags; see `to_int_flags`.
pub fn to_int64_flags(
  x : Double,
  direction : RoundingDirection,
  exact~ : Bool = false,
) -> (Int64?, Flags) {
  match int64_checked_rounded(x, direction) {
    None => (None, Flags::invalid_only())
    Some(v) =>
      (
        Some(v),
        { ..Flags::none(), inexact: exact && rounded(x, direction) != x, },
      )
  }
}

///|
/// convertToInteger to `UInt` with its flags; see `to_int_flags`.
pub fn to_uint_flags(
  x : Double,
  direction : RoundingDirection,
  exact~ : Bool = false,
) -> (UInt32?, Flags) {
  match uint_checked_rounded(x, direction) {
    None => (None, Flags::invalid_only())
    Some(v) =>
      (
        Some(v),
        { ..Flags::none(), inexact: exact && rounded(x, direction) != x, },
      )
  }
}

///|
/// convertToInteger to `UInt64` with its flags; see `to_int_flags`.
pub fn to_uint64_flags(
  x : Double,
  direction : RoundingDirection,
  exact~ : Bool = false,
) -> (UInt64?, Flags) {
  match uint64_checked_rounded(x, direction) {
    None => (None, Flags::invalid_only())
    Some(v) =>
      (
        Some(v),
        { ..Flags::none(), inexact: exact && rounded(x, direction) != x, },
      )
  }
}
