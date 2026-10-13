///|
fn nanq_bits(bits : UInt64) -> UInt64 {
  bits | 0x8000000000000UL
}

///|
/// IEEE 754-2019 §5.3.1 nextUp on a raw encoding. A NaN becomes quiet and keeps its
/// sign and payload; `nextUp(-0)` and `nextUp(+0)` are the smallest positive value.
pub fn next_up_bits(bits : UInt64) -> UInt64 {
  if is_nan_bits(bits) {
    nanq_bits(bits)
  } else if is_zero_bits(bits) {
    1UL
  } else if bits == 0x7ff0000000000000UL {
    bits
  } else if is_sign_minus_bits(bits) {
    bits - 1UL
  } else {
    bits + 1UL
  }
}

///|
/// IEEE 754-2019 §5.3.1 nextDown on a raw encoding: `-nextUp(-x)`.
pub fn next_down_bits(bits : UInt64) -> UInt64 {
  negate_bits(next_up_bits(negate_bits(bits)))
}

///|
/// nextUp on a portable value; every NaN gives the canonical quiet NaN.
pub fn next_up(x : Double) -> Double {
  next_up_bits(to_bits_canonical(x)).reinterpret_as_double()
}

///|
/// nextDown on a portable value; every NaN gives the canonical quiet NaN.
pub fn next_down(x : Double) -> Double {
  next_down_bits(to_bits_canonical(x)).reinterpret_as_double()
}

///|
/// Normalized significand and exponent of a finite nonzero encoding: the
/// magnitude is `sig * 2^exp` and `sig` has bit 52 set.
fn decode_normalized(bits : UInt64) -> (UInt64, Int32) {
  let e = ((bits >> 52) & 0x7ffUL).to_int()
  let f = bits & 0xfffffffffffffUL
  if e == 0 {
    let shift = f.clz() - 11
    (f << shift, -1074 - shift)
  } else {
    (f | (1UL << 52), e - 1075)
  }
}

///|
/// Build an encoding from an exactly representable value `mag * 2^e`.
fn pack_exact(sign : UInt64, mag : UInt64, e : Int32) -> UInt64 {
  if mag == 0UL {
    sign
  } else {
    let top = 63 - mag.clz()
    let unbiased = e + top
    if unbiased >= -1022 {
      let frac = if top <= 52 {
        (mag << (52 - top)) & 0xfffffffffffffUL
      } else {
        (mag >> (top - 52)) & 0xfffffffffffffUL
      }
      sign | (((unbiased + 1023).to_uint64() << 52) | frac)
    } else {
      let s = e - -1074
      let frac = if s >= 0 { mag << s } else { mag >> -s }
      sign | frac
    }
  }
}

///|
/// IEEE 754-2019 §5.3.1 remainder on raw encodings: `x - y * n` with `n` the integer
/// nearest `x / y` (ties to even), always exact. A NaN operand gives a quiet NaN that keeps
/// its payload; an infinite `x` or a zero `y` is invalid and gives the canonical quiet NaN;
/// `remainder(x, inf)` is `x`; a zero result has the sign of `x`.
pub fn remainder_bits(x : UInt64, y : UInt64) -> UInt64 {
  if is_nan_bits(x) {
    nanq_bits(x)
  } else if is_nan_bits(y) {
    nanq_bits(y)
  } else if is_infinite_bits(x) || is_zero_bits(y) {
    0x7ff8000000000000UL
  } else if is_infinite_bits(y) || is_zero_bits(x) {
    x
  } else {
    let (a, ex) = decode_normalized(x)
    let (b, ey) = decode_normalized(y)
    if ey - ex >= 2 {
      x
    } else {
      let mut r = a
      let mut q_odd = false
      let mut divisor = b
      let mut unit = ey
      if ex >= ey {
        if r >= b {
          r = r - b
          q_odd = true
        }
        for _ in 0..<(ex - ey) {
          r = r << 1
          q_odd = false
          if r >= b {
            r = r - b
            q_odd = true
          }
        }
      } else {
        divisor = b << 1
        unit = ex
      }
      let twice = r << 1
      let sign_x = x & 0x8000000000000000UL
      if twice > divisor || (twice == divisor && q_odd) {
        let mag = divisor - r
        pack_exact(
          if mag == 0UL {
            sign_x
          } else {
            sign_x ^ 0x8000000000000000UL
          },
          mag,
          unit,
        )
      } else {
        pack_exact(sign_x, r, unit)
      }
    }
  }
}

///|
/// remainder on portable values; every NaN result is the canonical quiet NaN.
pub fn remainder(x : Double, y : Double) -> Double {
  remainder_bits(to_bits_canonical(x), to_bits_canonical(y)).reinterpret_as_double()
}

///|
/// IEEE 754-2019 §5.3.3 logB of a raw encoding as an integer: the exponent `floor(log2 |x|)`
/// computed as though the range were unbounded, so subnormals give their true exponent. `None`
/// for NaN, infinities and zeros, which the standard declares exceptional.
pub fn logb_bits(bits : UInt64) -> Int32? {
  let e = ((bits >> 52) & 0x7ffUL).to_int()
  let f = bits & 0xfffffffffffffUL
  if e == 2047 {
    None
  } else if e == 0 {
    if f == 0UL {
      None
    } else {
      Some(63 - f.clz() + -1074)
    }
  } else {
    Some(e - 1023)
  }
}

///|
/// logB on a portable value with a floating-point result: NaN gives the canonical quiet NaN,
/// `logB(inf)` is `+inf` and `logB(0)` is `-inf`.
pub fn logb(x : Double) -> Double {
  let bits = to_bits_canonical(x)
  if is_nan_bits(bits) {
    0x7ff8000000000000UL.reinterpret_as_double()
  } else if is_infinite_bits(bits) {
    0x7ff0000000000000UL.reinterpret_as_double()
  } else {
    match logb_bits(bits) {
      Some(e) => e.to_double()
      None =>
        (0x8000000000000000UL | 0x7ff0000000000000UL).reinterpret_as_double()
    }
  }
}

///|
/// IEEE 754-2019 §5.3.3 scaleB on a raw encoding: `x * 2^n` rounded once by `direction`, with the
/// flags of §7 (invalid for a signaling NaN; overflow, underflow and inexact from the rounding).
/// A NaN becomes quiet, infinities, zeros and `n = 0` return `x`.
pub fn scaleb_bits_flags(
  bits : UInt64,
  n : Int32,
  direction : RoundingDirection,
) -> (UInt64, Flags) {
  if is_nan_bits(bits) {
    (nanq_bits(bits), { ..Flags::none(), invalid: is_signaling_bits(bits), })
  } else if is_infinite_bits(bits) || is_zero_bits(bits) || n == 0 {
    (bits, Flags::none())
  } else {
    let (m, e0) = decode_normalized(bits)
    let nn = if n > 2400 { 2400 } else if n < -2400 { -2400 } else { n }
    round_pack_flags(
      (bits & 0x8000000000000000UL) != 0UL,
      { hi: 0UL, lo: m, },
      e0 + nn,
      52,
      direction,
    )
  }
}

///|
/// scaleB on a raw encoding rounded by `direction`, without the flags.
pub fn scaleb_bits_with(
  bits : UInt64,
  n : Int32,
  direction : RoundingDirection,
) -> UInt64 {
  scaleb_bits_flags(bits, n, direction).0
}

///|
/// scaleB with the default rounding (ties to even).
pub fn scaleb_bits(bits : UInt64, n : Int32) -> UInt64 {
  scaleb_bits_with(bits, n, TiesToEven)
}

///|
/// scaleB on a portable value rounded by `direction`; every NaN gives the canonical quiet NaN.
pub fn scaleb_with(
  x : Double,
  n : Int32,
  direction : RoundingDirection,
) -> Double {
  scaleb_bits_with(to_bits_canonical(x), n, direction).reinterpret_as_double()
}

///|
/// scaleB on a portable value with ties to even.
pub fn scaleb(x : Double, n : Int32) -> Double {
  scaleb_with(x, n, TiesToEven)
}
