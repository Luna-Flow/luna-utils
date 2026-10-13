///|
fn nanq_bits(bits : UInt32) -> UInt32 {
  bits | 0x400000U
}

///|
/// IEEE 754-2019 §5.3.1 nextUp on a raw encoding. A NaN becomes quiet and keeps its
/// sign and payload; `nextUp(-0)` and `nextUp(+0)` are the smallest positive value.
pub fn next_up_bits(bits : UInt32) -> UInt32 {
  if is_nan_bits(bits) {
    nanq_bits(bits)
  } else if is_zero_bits(bits) {
    1U
  } else if bits == 0x7f800000U {
    bits
  } else if is_sign_minus_bits(bits) {
    bits - 1U
  } else {
    bits + 1U
  }
}

///|
/// IEEE 754-2019 §5.3.1 nextDown on a raw encoding: `-nextUp(-x)`.
pub fn next_down_bits(bits : UInt32) -> UInt32 {
  negate_bits(next_up_bits(negate_bits(bits)))
}

///|
/// nextUp on a portable value; every NaN gives the canonical quiet NaN.
pub fn next_up(x : Float) -> Float {
  Float::reinterpret_from_uint(next_up_bits(to_bits_canonical(x)))
}

///|
/// nextDown on a portable value; every NaN gives the canonical quiet NaN.
pub fn next_down(x : Float) -> Float {
  Float::reinterpret_from_uint(next_down_bits(to_bits_canonical(x)))
}

///|
/// Normalized significand and exponent of a finite nonzero encoding: the
/// magnitude is `sig * 2^exp` and `sig` has bit 23 set.
fn decode_normalized(bits : UInt32) -> (UInt64, Int32) {
  let e = ((bits >> 23) & 0xffU).reinterpret_as_int()
  let f = (bits & 0x7fffffU).to_uint64()
  if e == 0 {
    let shift = f.clz() - 40
    (f << shift, -149 - shift)
  } else {
    (f | (1UL << 23), e - 150)
  }
}

///|
/// Build an encoding from an exactly representable value `mag * 2^e`.
fn pack_exact(sign : UInt32, mag : UInt64, e : Int32) -> UInt32 {
  if mag == 0UL {
    sign
  } else {
    let top = 63 - mag.clz()
    let unbiased = e + top
    if unbiased >= -126 {
      let frac = if top <= 23 {
        (mag << (23 - top)) & 0x7fffffU.to_uint64()
      } else {
        (mag >> (top - 23)) & 0x7fffffU.to_uint64()
      }
      sign | (((unbiased + 127).to_uint64() << 23) | frac).to_uint()
    } else {
      let s = e - -149
      let frac = if s >= 0 { mag << s } else { mag >> -s }
      sign | frac.to_uint()
    }
  }
}

///|
/// IEEE 754-2019 §5.3.1 remainder on raw encodings: `x - y * n` with `n` the integer
/// nearest `x / y` (ties to even), always exact. A NaN operand gives a quiet NaN that keeps
/// its payload; an infinite `x` or a zero `y` is invalid and gives the canonical quiet NaN;
/// `remainder(x, inf)` is `x`; a zero result has the sign of `x`.
pub fn remainder_bits(x : UInt32, y : UInt32) -> UInt32 {
  if is_nan_bits(x) {
    nanq_bits(x)
  } else if is_nan_bits(y) {
    nanq_bits(y)
  } else if is_infinite_bits(x) || is_zero_bits(y) {
    0x7fc00000U
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
      let sign_x = x & 0x80000000U
      if twice > divisor || (twice == divisor && q_odd) {
        let mag = divisor - r
        pack_exact(
          if mag == 0UL {
            sign_x
          } else {
            sign_x ^ 0x80000000U
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
pub fn remainder(x : Float, y : Float) -> Float {
  Float::reinterpret_from_uint(
    remainder_bits(to_bits_canonical(x), to_bits_canonical(y)),
  )
}

///|
/// IEEE 754-2019 §5.3.3 logB of a raw encoding as an integer: the exponent `floor(log2 |x|)`
/// computed as though the range were unbounded, so subnormals give their true exponent. `None`
/// for NaN, infinities and zeros, which the standard declares exceptional.
pub fn logb_bits(bits : UInt32) -> Int32? {
  let e = ((bits >> 23) & 0xffU).reinterpret_as_int()
  let f = (bits & 0x7fffffU).to_uint64()
  if e == 255 {
    None
  } else if e == 0 {
    if f == 0UL {
      None
    } else {
      Some(63 - f.clz() + -149)
    }
  } else {
    Some(e - 127)
  }
}

///|
/// logB on a portable value with a floating-point result: NaN gives the canonical quiet NaN,
/// `logB(inf)` is `+inf` and `logB(0)` is `-inf`.
pub fn logb(x : Float) -> Float {
  let bits = to_bits_canonical(x)
  if is_nan_bits(bits) {
    Float::reinterpret_from_uint(0x7fc00000U)
  } else if is_infinite_bits(bits) {
    Float::reinterpret_from_uint(0x7f800000U)
  } else {
    match logb_bits(bits) {
      Some(e) => Float::from_int(e)
      None => Float::reinterpret_from_uint(0x80000000U | 0x7f800000U)
    }
  }
}

///|
/// IEEE 754-2019 §5.3.3 scaleB on a raw binary32 encoding: `x * 2^n` rounded once by `direction`,
/// with the flags of §7 (invalid for a signaling NaN; overflow, underflow and inexact from the
/// rounding). A NaN becomes quiet, infinities, zeros and `n = 0` return `x`.
pub fn scaleb_bits_flags(
  bits : UInt32,
  n : Int32,
  direction : @binary64.RoundingDirection,
) -> (UInt32, @binary64.Flags) {
  if is_nan_bits(bits) {
    (
      nanq_bits(bits),
      { ..@binary64.Flags::none(), invalid: is_signaling_bits(bits), },
    )
  } else if is_infinite_bits(bits) || is_zero_bits(bits) || n == 0 {
    (bits, @binary64.Flags::none())
  } else {
    let (m, e0) = decode_normalized(bits)
    let nn = if n > 2400 { 2400 } else if n < -2400 { -2400 } else { n }
    let (r, flags) = @binary64.round_exact_flags(
      (bits & 0x80000000U) != 0U,
      m,
      e0 + nn,
      23,
      direction,
    )
    (r.to_uint(), flags)
  }
}

///|
/// scaleB on a raw binary32 encoding rounded by `direction`, without the flags.
pub fn scaleb_bits_with(
  bits : UInt32,
  n : Int32,
  direction : @binary64.RoundingDirection,
) -> UInt32 {
  scaleb_bits_flags(bits, n, direction).0
}

///|
/// scaleB with the default rounding (ties to even).
pub fn scaleb_bits(bits : UInt32, n : Int32) -> UInt32 {
  scaleb_bits_with(bits, n, @binary64.TiesToEven)
}

///|
/// scaleB on a portable value rounded by `direction`; every NaN gives the canonical quiet NaN.
pub fn scaleb_with(
  x : Float,
  n : Int32,
  direction : @binary64.RoundingDirection,
) -> Float {
  Float::reinterpret_from_uint(
    scaleb_bits_with(to_bits_canonical(x), n, direction),
  )
}

///|
/// scaleB on a portable value with ties to even.
pub fn scaleb(x : Float, n : Int32) -> Float {
  scaleb_with(x, n, @binary64.TiesToEven)
}
