///|
/// IEEE 754-2019 §5.9 directions for roundToIntegral.
pub(all) enum RoundingDirection {
  TiesToEven
  TiesToAway
  TowardZero
  TowardPositive
  TowardNegative
} derive(Eq)

///|
pub extend RoundingDirection with Eq::{equal, not_equal}

///|
fn round_bits(bits : UInt64, direction : RoundingDirection) -> UInt64 {
  let sign = bits & 0x8000000000000000UL
  let exponent = ((bits >> 52) & 0x7ffUL).to_int()
  let fraction = bits & 0xfffffffffffffUL
  if exponent == 0x7ff {
    if fraction != 0UL {
      0x7ff8000000000000UL
    } else {
      bits
    }
  } else if exponent == 0 && fraction == 0UL {
    bits
  } else {
    let unbiased = exponent - 1023
    if unbiased >= 52 {
      bits
    } else if unbiased < 0 {
      let increment = match direction {
        TowardPositive => sign == 0UL
        TowardNegative => sign != 0UL
        TiesToAway => unbiased == -1
        TiesToEven => unbiased == -1 && fraction != 0UL
        TowardZero => false
      }
      if increment {
        sign | 0x3ff0000000000000UL
      } else {
        sign
      }
    } else {
      let discarded = 52 - unbiased
      let mask = (1UL << discarded) - 1UL
      let kept = bits & (0xffffffffffffffffUL ^ mask)
      let remainder = bits & mask
      if remainder == 0UL {
        bits
      } else {
        let increment = match direction {
          TowardPositive => sign == 0UL
          TowardNegative => sign != 0UL
          TowardZero => false
          TiesToAway => remainder >= 1UL << (discarded - 1)
          TiesToEven => {
            let half = 1UL << (discarded - 1)
            remainder > half ||
            (remainder == half && (kept & (1UL << discarded)) != 0UL)
          }
        }
        if increment {
          kept + (1UL << discarded)
        } else {
          kept
        }
      }
    }
  }
}

///|
/// Round to an integral binary64 value in the requested IEEE 754 direction.
pub fn round_to_integral(x : Double, direction : RoundingDirection) -> Double {
  round_bits(to_bits_canonical(x), direction).reinterpret_as_double()
}

///|
pub fn round_ties_even(x : Double) -> Double {
  round_to_integral(x, TiesToEven)
}

///|
pub fn round_ties_away(x : Double) -> Double {
  round_to_integral(x, TiesToAway)
}

///|
pub fn round_toward_zero(x : Double) -> Double {
  round_to_integral(x, TowardZero)
}

///|
pub fn round_toward_positive(x : Double) -> Double {
  round_to_integral(x, TowardPositive)
}

///|
pub fn round_toward_negative(x : Double) -> Double {
  round_to_integral(x, TowardNegative)
}
