///|
/// IEEE 754-2019 §5.4.2 convertFormat from binary32 to binary64 on a raw encoding. The
/// conversion is always exact. A NaN becomes a quiet NaN that keeps its sign and its 22
/// payload bits (shifted up), so narrowing it back changes nothing (§6.2.3).
pub fn to_binary64_bits(bits : UInt32) -> UInt64 {
  let sign = (bits.to_uint64() & 0x80000000UL) << 32
  if is_nan_bits(bits) {
    sign | 0x7ff8000000000000UL | ((bits & 0x3fffffU).to_uint64() << 29)
  } else if is_infinite_bits(bits) {
    sign | 0x7ff0000000000000UL
  } else if is_zero_bits(bits) {
    sign
  } else {
    let e = ((bits >> 23) & 0xffU).reinterpret_as_int()
    let f = (bits & 0x7fffffU).to_uint64()
    if e == 0 {
      // subnormal binary32: normalize into the wider exponent range
      let shift = f.clz() - 11
      let m = f << shift
      let t = -126 - (shift - 29)
      sign | ((t + 1023).to_uint64() << 52) | (m & 0xfffffffffffffUL)
    } else {
      sign | ((e + 896).to_uint64() << 52) | (f << 29)
    }
  }
}

///|
/// convertFormat of a portable binary32 value to binary64 (exact); every NaN gives the
/// canonical quiet NaN.
pub fn to_binary64(x : Float) -> Double {
  to_binary64_bits(to_bits_canonical(x)).reinterpret_as_double()
}
