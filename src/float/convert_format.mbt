///|
/// Smallest-magnitude overflow result of a conversion to binary32: infinity or the
/// largest finite value, depending on the rounding direction and the sign.
fn narrow_overflow(sign : UInt32, direction : RoundingDirection) -> UInt32 {
  let inf = sign | 0x7f800000U
  let max_finite = sign | 0x7f7fffffU
  match direction {
    TiesToEven | TiesToAway => inf
    TowardZero => max_finite
    TowardPositive => if sign == 0U { inf } else { max_finite }
    TowardNegative => if sign == 0U { max_finite } else { inf }
  }
}

///|
/// IEEE 754-2019 §5.4.2 convertFormat from binary64 to binary32 on a raw encoding, rounded
/// once by `direction` with gradual underflow. Zeros and infinities keep their sign. A NaN
/// becomes a quiet NaN that keeps its sign and the high 22 payload bits, so widening a quiet
/// NaN and narrowing it back changes nothing (§6.2.3).
pub fn to_binary32_bits_with(
  bits : UInt64,
  direction : RoundingDirection,
) -> UInt32 {
  let sign = (bits >> 32).to_uint() & 0x80000000U
  if is_nan_bits(bits) {
    sign | 0x7fc00000U | ((bits >> 29).to_uint() & 0x3fffffU)
  } else if is_infinite_bits(bits) {
    sign | 0x7f800000U
  } else if is_zero_bits(bits) {
    sign
  } else {
    let e = ((bits >> 52) & 0x7ffUL).to_int()
    let f = bits & 0xfffffffffffffUL
    let mut m = f | 0x10000000000000UL
    let mut t = e - 1023
    if e == 0 {
      let shift = f.clz() - 11
      m = f << shift
      t = -1022 - shift
    }
    if t > 127 {
      narrow_overflow(sign, direction)
    } else {
      let shift = if t >= -126 { 29 } else { 29 + (-126 - t) }
      let mut kept = 0UL
      let mut cmp = -1
      let mut inexact = true
      if shift < 64 {
        kept = m >> shift
        let rem = m & ((1UL << shift) - 1UL)
        let half = 1UL << (shift - 1)
        cmp = if rem < half { -1 } else if rem == half { 0 } else { 1 }
        inexact = rem != 0UL
      }
      let negative = sign != 0U
      let increment = match direction {
        TiesToEven => cmp > 0 || (cmp == 0 && (kept & 1UL) == 1UL)
        TiesToAway => cmp >= 0
        TowardZero => false
        TowardPositive => !negative && inexact
        TowardNegative => negative && inexact
      }
      let rounded = kept + (if increment { 1UL } else { 0UL })
      if t >= -126 {
        let mut field = t + 127
        let mut sig = rounded
        if sig == 0x1000000UL {
          sig = 0x800000UL
          field = field + 1
        }
        if field >= 255 {
          narrow_overflow(sign, direction)
        } else {
          sign |
          (field.reinterpret_as_uint() << 23) |
          (sig.to_uint() & 0x7fffffU)
        }
      } else {
        sign | rounded.to_uint()
      }
    }
  }
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
