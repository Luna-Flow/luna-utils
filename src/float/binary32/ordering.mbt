///|
fn total_order_key_bits(bits : UInt) -> Int {
  let sign = bits >> 31
  (bits ^ (if sign != 0U { 0x7fffffffU } else { 0U })).reinterpret_as_int()
}

///|
/// IEEE 754-2019 §5.10 totalOrder on raw binary32 encodings.
/// The comparison preserves NaN sign, signaling state and payload.
pub fn total_order_bits(x : UInt, y : UInt) -> Bool {
  total_order_key_bits(x) <= total_order_key_bits(y)
}

///|
/// IEEE 754-2019 §5.10 totalOrder on portable binary32 values.
/// Numeric NaNs are compared as the package's positive canonical quiet NaN.
pub fn portable_total_order(x : Float, y : Float) -> Bool {
  total_order_bits(to_bits_canonical(x), to_bits_canonical(y))
}

///|
/// IEEE 754-2019 §9.6 minimum. NaN inputs produce positive canonical quiet NaN.
pub fn minimum(x : Float, y : Float) -> Float {
  if x != x || y != y {
    Float::reinterpret_from_uint(0x7fc00000U)
  } else {
    let xb = to_bits_canonical(x)
    let yb = to_bits_canonical(y)
    if is_zero_bits(xb) && is_zero_bits(yb) {
      Float::reinterpret_from_uint(xb | yb)
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
pub fn maximum(x : Float, y : Float) -> Float {
  if x != x || y != y {
    Float::reinterpret_from_uint(0x7fc00000U)
  } else {
    let xb = to_bits_canonical(x)
    let yb = to_bits_canonical(y)
    if is_zero_bits(xb) && is_zero_bits(yb) {
      Float::reinterpret_from_uint(xb & yb)
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
/// Sort binary32 values in portable totalOrder order.
pub fn sort_total_order(values : Array[Float]) -> Unit {
  sort_total_order_view(values.mut_view())
}

///|
/// Sort a mutable binary32 view in portable totalOrder order.
pub fn sort_total_order_view(values : MutArrayView[Float]) -> Unit {
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
