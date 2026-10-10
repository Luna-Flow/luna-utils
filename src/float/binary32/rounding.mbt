///|
fn round_bits(bits : UInt, direction : @binary64.RoundingDirection) -> UInt {
  let sign = bits & 0x80000000U
  let exponent = ((bits >> 23) & 0xffU).reinterpret_as_int()
  let fraction = bits & 0x7fffffU
  if exponent == 0xff {
    if fraction != 0U {
      0x7fc00000U
    } else {
      bits
    }
  } else if exponent == 0 && fraction == 0U {
    bits
  } else {
    let unbiased = exponent - 127
    if unbiased >= 23 {
      bits
    } else if unbiased < 0 {
      let increment = match direction {
        @binary64.TowardPositive => sign == 0U
        @binary64.TowardNegative => sign != 0U
        @binary64.TiesToAway => unbiased == -1
        @binary64.TiesToEven => unbiased == -1 && fraction != 0U
        @binary64.TowardZero => false
      }
      if increment {
        sign | 0x3f800000U
      } else {
        sign
      }
    } else {
      let discarded = 23 - unbiased
      let mask = (1U << discarded) - 1U
      let kept = bits & (0xffffffffU ^ mask)
      let remainder = bits & mask
      if remainder == 0U {
        bits
      } else {
        let increment = match direction {
          @binary64.TowardPositive => sign == 0U
          @binary64.TowardNegative => sign != 0U
          @binary64.TowardZero => false
          @binary64.TiesToAway => remainder >= 1U << (discarded - 1)
          @binary64.TiesToEven => {
            let half = 1U << (discarded - 1)
            remainder > half ||
            (remainder == half && (kept & (1U << discarded)) != 0U)
          }
        }
        if increment {
          kept + (1U << discarded)
        } else {
          kept
        }
      }
    }
  }
}

///|
/// Round to an integral binary32 value in the requested IEEE 754 direction.
pub fn round_to_integral(
  x : Float,
  direction : @binary64.RoundingDirection,
) -> Float {
  Float::reinterpret_from_uint(round_bits(to_bits_canonical(x), direction))
}

///|
pub fn round_ties_even(x : Float) -> Float {
  round_to_integral(x, @binary64.TiesToEven)
}

///|
pub fn round_ties_away(x : Float) -> Float {
  round_to_integral(x, @binary64.TiesToAway)
}

///|
pub fn round_toward_zero(x : Float) -> Float {
  round_to_integral(x, @binary64.TowardZero)
}

///|
pub fn round_toward_positive(x : Float) -> Float {
  round_to_integral(x, @binary64.TowardPositive)
}

///|
pub fn round_toward_negative(x : Float) -> Float {
  round_to_integral(x, @binary64.TowardNegative)
}
