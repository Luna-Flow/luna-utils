///|
/// A 128-bit unsigned integer for the exact alignment and rounding of fusedMultiplyAdd.
priv struct U128 {
  hi : UInt64
  lo : UInt64
}

///|
fn u128_is_zero(a : U128) -> Bool {
  a.hi == 0UL && a.lo == 0UL
}

///|
fn u128_shl(a : U128, n : Int32) -> U128 {
  if n == 0 {
    a
  } else if n >= 64 {
    { hi: a.lo << (n - 64), lo: 0UL, }
  } else {
    { hi: (a.hi << n) | (a.lo >> (64 - n)), lo: a.lo << n, }
  }
}

///|
fn u128_shr(a : U128, n : Int32) -> U128 {
  if n == 0 {
    a
  } else if n >= 64 {
    { hi: 0UL, lo: a.hi >> (n - 64), }
  } else {
    { hi: a.hi >> n, lo: (a.lo >> n) | (a.hi << (64 - n)), }
  }
}

///|
fn u128_add(a : U128, b : U128) -> U128 {
  let lo = a.lo + b.lo
  let carry = if lo < a.lo { 1UL } else { 0UL }
  { hi: a.hi + b.hi + carry, lo, }
}

///|
fn u128_sub(a : U128, b : U128) -> U128 {
  let borrow = if a.lo < b.lo { 1UL } else { 0UL }
  { hi: a.hi - b.hi - borrow, lo: a.lo - b.lo, }
}

///|
fn u128_cmp(a : U128, b : U128) -> Int32 {
  if a.hi < b.hi {
    -1
  } else if a.hi > b.hi {
    1
  } else if a.lo < b.lo {
    -1
  } else if a.lo > b.lo {
    1
  } else {
    0
  }
}

///|
fn u128_clz(a : U128) -> Int32 {
  if a.hi != 0UL {
    a.hi.clz()
  } else if a.lo != 0UL {
    64 + a.lo.clz()
  } else {
    128
  }
}

///|
/// Shift right by `n` bits; any bit shifted out sets the lowest bit of the result (a sticky bit).
fn u128_shr_jam(a : U128, n : Int32) -> U128 {
  if n == 0 {
    a
  } else if n >= 128 {
    if u128_is_zero(a) {
      a
    } else {
      { hi: 0UL, lo: 1UL, }
    }
  } else {
    let r = u128_shr(a, n)
    if u128_cmp(u128_shl(r, n), a) == 0 {
      r
    } else {
      { hi: r.hi, lo: r.lo | 1UL, }
    }
  }
}

///|
/// Full product of two 64-bit values.
fn mul_wide(a : UInt64, b : UInt64) -> U128 {
  let a0 = a & 0xffffffffUL
  let a1 = a >> 32
  let b0 = b & 0xffffffffUL
  let b1 = b >> 32
  let p00 = a0 * b0
  let p01 = a0 * b1
  let p10 = a1 * b0
  let p11 = a1 * b1
  let mid = (p00 >> 32) + (p01 & 0xffffffffUL) + (p10 & 0xffffffffUL)
  {
    hi: p11 + (p01 >> 32) + (p10 >> 32) + (mid >> 32),
    lo: (p00 & 0xffffffffUL) | (mid << 32),
  }
}

///|
/// Result of an overflow in a format with `mbits` fraction bits: infinity or the largest
/// finite value, depending on the rounding direction and the sign.
fn overflow_bits(
  negative : Bool,
  mbits : Int32,
  direction : RoundingDirection,
) -> UInt64 {
  let exp_field = if mbits == 52 { 0x7ffUL } else { 0xffUL }
  let sign = if negative {
    if mbits == 52 {
      0x8000000000000000UL
    } else {
      0x80000000UL
    }
  } else {
    0UL
  }
  let inf = sign | (exp_field << mbits)
  let max_finite = sign |
    (((exp_field - 1UL) << mbits) | ((1UL << mbits) - 1UL))
  match direction {
    TiesToEven | TiesToAway => inf
    TowardZero => max_finite
    TowardPositive => if negative { max_finite } else { inf }
    TowardNegative => if negative { inf } else { max_finite }
  }
}

///|
/// Round the exact value `s * 2^e` (with `s` nonzero) to a format with `mbits` fraction bits
/// by `direction`, with gradual underflow. A sticky bit in the lowest bit of `s` stands for
/// any nonzero amount below it.
fn round_pack_u128(
  negative : Bool,
  s : U128,
  e : Int32,
  mbits : Int32,
  direction : RoundingDirection,
) -> UInt64 {
  let bias = if mbits == 52 { 1023 } else { 127 }
  let exp_field_max = if mbits == 52 { 2047 } else { 255 }
  let sign = if negative {
    if mbits == 52 {
      0x8000000000000000UL
    } else {
      0x80000000UL
    }
  } else {
    0UL
  }
  let msb = 127 - u128_clz(s)
  let t = e + msb
  let emin = 1 - bias
  let mut shift = msb - mbits
  if t < emin {
    shift = shift + (emin - t)
  }
  let mut kept = 0UL
  let mut cmp = -1
  let mut inexact = false
  if shift <= 0 {
    kept = s.lo << -shift
  } else if shift >= 128 {
    inexact = true
  } else {
    let k = u128_shr(s, shift)
    kept = k.lo
    let rem = u128_sub(s, u128_shl(k, shift))
    let half = u128_shl({ hi: 0UL, lo: 1UL, }, shift - 1)
    cmp = u128_cmp(rem, half)
    inexact = !u128_is_zero(rem)
  }
  let increment = match direction {
    TiesToEven => cmp > 0 || (cmp == 0 && inexact && (kept & 1UL) == 1UL)
    TiesToAway => inexact && cmp >= 0
    TowardZero => false
    TowardPositive => !negative && inexact
    TowardNegative => negative && inexact
  }
  let rounded = kept + (if increment { 1UL } else { 0UL })
  if t >= emin {
    let mut field = t + bias
    let mut sig = rounded
    if sig == 1UL << (mbits + 1) {
      sig = 1UL << mbits
      field = field + 1
    }
    if field >= exp_field_max {
      overflow_bits(negative, mbits, direction)
    } else {
      sign | (field.to_uint64() << mbits) | (sig & ((1UL << mbits) - 1UL))
    }
  } else {
    sign | rounded
  }
}

///|
fn zero_bits_for(negative : Bool, mbits : Int32) -> UInt64 {
  if negative {
    if mbits == 52 {
      0x8000000000000000UL
    } else {
      0x80000000UL
    }
  } else {
    0UL
  }
}

///|
/// Shared engine of fusedMultiplyAdd for finite operands given as binary64 encodings (a binary32
/// operand is widened exactly first): the exact value `x * y + z` rounded once by `direction` to
/// the format with `mbits` (52 or 23) fraction bits, returned as an encoding of that format.
/// Use `fma_bits_with` and `fma_with` (and the `float/binary32` versions) instead of calling this.
pub fn fma_finite_bits(
  x : UInt64,
  y : UInt64,
  z : UInt64,
  mbits : Int32,
  direction : RoundingDirection,
) -> UInt64 {
  let negative_product = ((x ^ y) & 0x8000000000000000UL) != 0UL
  let negative_z = (z & 0x8000000000000000UL) != 0UL
  let product_zero = is_zero_bits(x) || is_zero_bits(y)
  let z_zero = is_zero_bits(z)
  if product_zero && z_zero {
    zero_bits_for(
      if negative_product == negative_z {
        negative_product
      } else {
        direction == TowardNegative
      },
      mbits,
    )
  } else if product_zero {
    let (mz, ez) = decode_normalized(z)
    round_pack_u128(negative_z, { hi: 0UL, lo: mz, }, ez, mbits, direction)
  } else {
    let (mx, ex) = decode_normalized(x)
    let (my, ey) = decode_normalized(y)
    let p = mul_wide(mx, my)
    let ep = ex + ey
    if z_zero {
      round_pack_u128(negative_product, p, ep, mbits, direction)
    } else {
      let (mz, ez) = decode_normalized(z)
      let a = u128_shl(p, 125 - (127 - u128_clz(p)))
      let ea = ep - (125 - (127 - u128_clz(p)))
      let b = u128_shl({ hi: 0UL, lo: mz, }, 73)
      let eb = ez - 73
      // `big` has the larger exponent (both have their top bit at bit 125); the other is
      // shifted right with a sticky bit. The larger operand is even, so the result of a sum or
      // difference with the sticky bit is odd and never sits on a rounding boundary.
      let (big, small, e, neg_big, neg_small) = if ea >= eb {
        (a, u128_shr_jam(b, ea - eb), ea, negative_product, negative_z)
      } else {
        (b, u128_shr_jam(a, eb - ea), eb, negative_z, negative_product)
      }
      if neg_big == neg_small {
        round_pack_u128(neg_big, u128_add(big, small), e, mbits, direction)
      } else {
        let c = u128_cmp(big, small)
        if c == 0 {
          zero_bits_for(direction == TowardNegative, mbits)
        } else if c > 0 {
          round_pack_u128(neg_big, u128_sub(big, small), e, mbits, direction)
        } else {
          round_pack_u128(neg_small, u128_sub(small, big), e, mbits, direction)
        }
      }
    }
  }
}

///|
/// IEEE 754-2019 §5.3.1 fusedMultiplyAdd on raw encodings: `x * y + z` rounded once by
/// `direction`. A NaN operand gives a quiet NaN that keeps its sign and payload (the first
/// of `x`, `y`, `z`); `inf * 0` and `inf - inf` give the canonical quiet NaN; an infinite
/// product or addend gives the infinity; the sign of an exact zero result follows §6.3.
pub fn fma_bits_with(
  x : UInt64,
  y : UInt64,
  z : UInt64,
  direction : RoundingDirection,
) -> UInt64 {
  if is_nan_bits(x) {
    nanq_bits(x)
  } else if is_nan_bits(y) {
    nanq_bits(y)
  } else if is_nan_bits(z) {
    nanq_bits(z)
  } else if (is_infinite_bits(x) && is_zero_bits(y)) ||
    (is_zero_bits(x) && is_infinite_bits(y)) {
    0x7ff8000000000000UL
  } else if is_infinite_bits(x) || is_infinite_bits(y) {
    let negative_product = ((x ^ y) & 0x8000000000000000UL) != 0UL
    if is_infinite_bits(z) &&
      ((z & 0x8000000000000000UL) != 0UL) != negative_product {
      0x7ff8000000000000UL
    } else if negative_product {
      0xfff0000000000000UL
    } else {
      0x7ff0000000000000UL
    }
  } else if is_infinite_bits(z) {
    z
  } else {
    fma_finite_bits(x, y, z, 52, direction)
  }
}

///|
/// fusedMultiplyAdd on raw encodings with ties to even.
pub fn fma_bits(x : UInt64, y : UInt64, z : UInt64) -> UInt64 {
  fma_bits_with(x, y, z, TiesToEven)
}

///|
/// fusedMultiplyAdd of portable values rounded by `direction`; every NaN gives the canonical
/// quiet NaN.
pub fn fma_with(
  x : Double,
  y : Double,
  z : Double,
  direction : RoundingDirection,
) -> Double {
  fma_bits_with(
    to_bits_canonical(x),
    to_bits_canonical(y),
    to_bits_canonical(z),
    direction,
  ).reinterpret_as_double()
}

///|
/// fusedMultiplyAdd of portable values with ties to even.
pub fn fma(x : Double, y : Double, z : Double) -> Double {
  fma_with(x, y, z, TiesToEven)
}
