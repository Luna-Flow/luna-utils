///|
fn total_order_key_bits(bits : UInt64) -> Int64 {
  let sign = bits >> 63
  (bits ^ (if sign != 0UL { 0x7fffffffffffffffUL } else { 0UL })).reinterpret_as_int64()
}

///|
/// IEEE 754-2019 §5.10 totalOrder on raw binary64 encodings.
/// The comparison preserves NaN sign, signaling state and payload.
pub fn total_order_bits(x : UInt64, y : UInt64) -> Bool {
  total_order_key_bits(x) <= total_order_key_bits(y)
}

///|
/// IEEE 754-2019 §5.10 totalOrder on portable binary64 values.
/// Numeric NaNs are compared as the package's positive canonical quiet NaN.
pub fn portable_total_order(x : Double, y : Double) -> Bool {
  total_order_bits(to_bits_canonical(x), to_bits_canonical(y))
}

///|
/// IEEE 754-2019 §9.6 minimum. NaN inputs produce positive canonical quiet NaN.
pub fn minimum(x : Double, y : Double) -> Double {
  if x != x || y != y {
    0x7ff8000000000000UL.reinterpret_as_double()
  } else {
    let xb = to_bits_canonical(x)
    let yb = to_bits_canonical(y)
    if is_zero_bits(xb) && is_zero_bits(yb) {
      (xb | yb).reinterpret_as_double()
    } else if x < y {
      x
    } else if y < x {
      y
    } else {
      x
    }
  }
}

///|
/// IEEE 754-2019 §9.6 maximum. NaN inputs produce positive canonical quiet NaN.
pub fn maximum(x : Double, y : Double) -> Double {
  if x != x || y != y {
    0x7ff8000000000000UL.reinterpret_as_double()
  } else {
    let xb = to_bits_canonical(x)
    let yb = to_bits_canonical(y)
    if is_zero_bits(xb) && is_zero_bits(yb) {
      (xb & yb).reinterpret_as_double()
    } else if x < y {
      y
    } else if y < x {
      x
    } else {
      x
    }
  }
}

///|
/// Sort binary64 values in portable totalOrder order.
pub fn sort_total_order(values : Array[Double]) -> Unit {
  sort_total_order_view(values.mut_view())
}

///|
/// Sort a mutable binary64 view in portable totalOrder order.
pub fn sort_total_order_view(values : MutArrayView[Double]) -> Unit {
  values.sort_by((x, y) => {
    let xb = total_order_key_bits(to_bits_canonical(x))
    let yb = total_order_key_bits(to_bits_canonical(y))
    if xb < yb {
      -1
    } else if xb > yb {
      1
    } else {
      0
    }
  })
}
