///|
/// IEEE 754-2019 §5.4.2 convertFormat from binary64 to binary32 on a raw encoding, rounded
/// once by `direction` with gradual underflow, with the flags of §7 (invalid for a signaling
/// NaN; overflow, underflow and inexact from the rounding). Zeros and infinities keep their sign.
/// A NaN becomes a quiet NaN that keeps its sign and the high 22 payload bits, so widening a quiet
/// NaN and narrowing it back changes nothing (§6.2.3).
pub fn to_binary32_bits_flags(
  bits : UInt64,
  direction : RoundingDirection,
) -> (UInt32, Flags) {
  let sign = (bits >> 32).to_uint() & 0x80000000U
  if is_nan_bits(bits) {
    (
      sign | 0x7fc00000U | ((bits >> 29).to_uint() & 0x3fffffU),
      { ..Flags::none(), invalid: is_signaling_bits(bits), },
    )
  } else if is_infinite_bits(bits) {
    (sign | 0x7f800000U, Flags::none())
  } else if is_zero_bits(bits) {
    (sign, Flags::none())
  } else {
    let (m, e) = decode_normalized(bits)
    let (r, flags) = round_pack_flags(
      sign != 0U,
      { hi: 0UL, lo: m, },
      e,
      23,
      direction,
    )
    (r.to_uint(), flags)
  }
}

///|
/// convertFormat from binary64 to binary32 on a raw encoding rounded by `direction`, without the flags.
pub fn to_binary32_bits_with(
  bits : UInt64,
  direction : RoundingDirection,
) -> UInt32 {
  to_binary32_bits_flags(bits, direction).0
}

///|
/// convertFormat from binary64 to binary32 on a raw encoding with ties to even.
pub fn to_binary32_bits(bits : UInt64) -> UInt32 {
  to_binary32_bits_with(bits, TiesToEven)
}

///|
/// convertFormat of a portable value to binary32, rounded by `direction`; every NaN gives
/// the canonical quiet NaN.
pub fn to_binary32_with(x : Double, direction : RoundingDirection) -> Float {
  Float::reinterpret_from_uint(
    to_binary32_bits_with(to_bits_canonical(x), direction),
  )
}

///|
/// convertFormat of a portable value to binary32 with ties to even.
pub fn to_binary32(x : Double) -> Float {
  to_binary32_with(x, TiesToEven)
}
