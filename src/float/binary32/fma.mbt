///|
/// IEEE 754-2019 §5.3.1 fusedMultiplyAdd on raw binary32 encodings: `x * y + z` rounded once by
/// `direction`; see `@float.fma_bits_with` for the special values.
pub fn fma_bits_flags(
  x : UInt32,
  y : UInt32,
  z : UInt32,
  direction : @binary64.RoundingDirection,
) -> (UInt32, @binary64.Flags) {
  let invalid_nan = is_signaling_bits(x) ||
    is_signaling_bits(y) ||
    is_signaling_bits(z)
  if is_nan_bits(x) {
    (x | 0x400000U, { ..@binary64.Flags::none(), invalid: invalid_nan, })
  } else if is_nan_bits(y) {
    (y | 0x400000U, { ..@binary64.Flags::none(), invalid: invalid_nan, })
  } else if is_nan_bits(z) {
    (z | 0x400000U, { ..@binary64.Flags::none(), invalid: invalid_nan, })
  } else if (is_infinite_bits(x) && is_zero_bits(y)) ||
    (is_zero_bits(x) && is_infinite_bits(y)) {
    (0x7fc00000U, @binary64.Flags::invalid_only())
  } else if is_infinite_bits(x) || is_infinite_bits(y) {
    let negative_product = ((x ^ y) & 0x80000000U) != 0U
    if is_infinite_bits(z) && ((z & 0x80000000U) != 0U) != negative_product {
      (0x7fc00000U, @binary64.Flags::invalid_only())
    } else if negative_product {
      (0xff800000U, @binary64.Flags::none())
    } else {
      (0x7f800000U, @binary64.Flags::none())
    }
  } else if is_infinite_bits(z) {
    (z, @binary64.Flags::none())
  } else {
    let (r, flags) = @binary64.fma_finite_flags(
      to_binary64_bits(x),
      to_binary64_bits(y),
      to_binary64_bits(z),
      23,
      direction,
    )
    (r.to_uint(), flags)
  }
}

///|
/// fusedMultiplyAdd on raw binary32 encodings rounded by `direction`, without the flags.
pub fn fma_bits_with(
  x : UInt32,
  y : UInt32,
  z : UInt32,
  direction : @binary64.RoundingDirection,
) -> UInt32 {
  fma_bits_flags(x, y, z, direction).0
}

///|
/// fusedMultiplyAdd on raw binary32 encodings with ties to even.
pub fn fma_bits(x : UInt32, y : UInt32, z : UInt32) -> UInt32 {
  fma_bits_with(x, y, z, @binary64.TiesToEven)
}

///|
/// fusedMultiplyAdd of portable binary32 values rounded by `direction`; every NaN gives the
/// canonical quiet NaN.
pub fn fma_with(
  x : Float,
  y : Float,
  z : Float,
  direction : @binary64.RoundingDirection,
) -> Float {
  Float::reinterpret_from_uint(
    fma_bits_with(
      to_bits_canonical(x),
      to_bits_canonical(y),
      to_bits_canonical(z),
      direction,
    ),
  )
}

///|
/// fusedMultiplyAdd of portable binary32 values with ties to even.
pub fn fma(x : Float, y : Float, z : Float) -> Float {
  fma_with(x, y, z, @binary64.TiesToEven)
}
