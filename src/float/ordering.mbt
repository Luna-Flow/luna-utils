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

///|
/// IEEE 754-2019 §5.10 totalOrderMag on raw encodings: totalOrder of the absolute values.
pub fn total_order_mag_bits(x : UInt64, y : UInt64) -> Bool {
  total_order_bits(abs_bits(x), abs_bits(y))
}

///|
/// IEEE 754-2019 §5.10 totalOrderMag on portable values; NaNs are compared as the canonical quiet NaN.
pub fn portable_total_order_mag(x : Double, y : Double) -> Bool {
  total_order_mag_bits(to_bits_canonical(x), to_bits_canonical(y))
}

///|
fn abs_value(x : Double) -> Double {
  if x < 0.0 || (x == 0.0 && is_sign_minus_bits(to_bits_canonical(x))) {
    -x
  } else {
    x
  }
}

///|
/// IEEE 754-2019 §9.6 minimumNumber: the number when exactly one operand is a NaN,
/// the canonical quiet NaN when both are, otherwise `minimum`. A signaling NaN cannot be
/// told from a quiet one in a numeric value, so no invalid operation is reported.
pub fn minimum_number(x : Double, y : Double) -> Double {
  if x != x {
    if y != y {
      0x7ff8000000000000UL.reinterpret_as_double()
    } else {
      y
    }
  } else if y != y {
    x
  } else {
    minimum(x, y)
  }
}

///|
/// IEEE 754-2019 §9.6 maximumNumber; see `minimum_number`.
pub fn maximum_number(x : Double, y : Double) -> Double {
  if x != x {
    if y != y {
      0x7ff8000000000000UL.reinterpret_as_double()
    } else {
      y
    }
  } else if y != y {
    x
  } else {
    maximum(x, y)
  }
}

///|
/// IEEE 754-2019 §9.6 minimumMagnitude: the operand of smaller magnitude, otherwise `minimum`.
pub fn minimum_magnitude(x : Double, y : Double) -> Double {
  if x == x && y == y {
    let ax = abs_value(x)
    let ay = abs_value(y)
    if ax < ay {
      x
    } else if ay < ax {
      y
    } else {
      minimum(x, y)
    }
  } else {
    minimum(x, y)
  }
}

///|
/// IEEE 754-2019 §9.6 maximumMagnitude: the operand of larger magnitude, otherwise `maximum`.
pub fn maximum_magnitude(x : Double, y : Double) -> Double {
  if x == x && y == y {
    let ax = abs_value(x)
    let ay = abs_value(y)
    if ax > ay {
      x
    } else if ay > ax {
      y
    } else {
      maximum(x, y)
    }
  } else {
    maximum(x, y)
  }
}

///|
/// IEEE 754-2019 §9.6 minimumMagnitudeNumber: smaller magnitude, otherwise `minimum_number`.
pub fn minimum_magnitude_number(x : Double, y : Double) -> Double {
  if x == x && y == y {
    let ax = abs_value(x)
    let ay = abs_value(y)
    if ax < ay {
      x
    } else if ay < ax {
      y
    } else {
      minimum_number(x, y)
    }
  } else {
    minimum_number(x, y)
  }
}

///|
/// IEEE 754-2019 §9.6 maximumMagnitudeNumber: larger magnitude, otherwise `maximum_number`.
pub fn maximum_magnitude_number(x : Double, y : Double) -> Double {
  if x == x && y == y {
    let ax = abs_value(x)
    let ay = abs_value(y)
    if ax > ay {
      x
    } else if ay > ax {
      y
    } else {
      maximum_number(x, y)
    }
  } else {
    maximum_number(x, y)
  }
}
