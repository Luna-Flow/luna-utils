///|
/// Classify an uninterpreted IEEE binary64 encoding, preserving all NaN bits.
pub fn classify_bits(bits : UInt64) -> Classification {
  let e = bits & 0x7ff0000000000000UL
  let f = bits & 0xfffffffffffffUL
  let negative = is_sign_minus_bits(bits)
  if e == 0x7ff0000000000000UL {
    if f != 0UL {
      if (bits & 0x8000000000000UL) == 0UL {
        SignalingNaN
      } else {
        QuietNaN
      }
    } else if negative {
      NegativeInfinity
    } else {
      PositiveInfinity
    }
  } else if e == 0UL {
    if f == 0UL {
      if negative {
        NegativeZero
      } else {
        PositiveZero
      }
    } else if negative {
      NegativeSubnormal
    } else {
      PositiveSubnormal
    }
  } else if negative {
    NegativeNormal
  } else {
    PositiveNormal
  }
}

///|
/// True exactly for NaN encodings (exponent all ones, nonzero fraction).
pub fn is_nan_bits(bits : UInt64) -> Bool {
  (bits & 0x7ff0000000000000UL) == 0x7ff0000000000000UL &&
  (bits & 0xfffffffffffffUL) != 0UL
}

///|
/// Signaling status is meaningful only for raw encodings, before float materialization.
pub fn is_signaling_bits(bits : UInt64) -> Bool {
  is_nan_bits(bits) && (bits & 0x8000000000000UL) == 0UL
}

///|
/// All non-NaN binary encodings are canonical; NaN uses one positive quiet encoding.
pub fn is_canonical_bits(bits : UInt64) -> Bool {
  !is_nan_bits(bits) || bits == 0x7ff8000000000000UL
}

///|
/// Replace every NaN encoding with the fixed positive quiet NaN.
pub fn canonicalize_nan_bits(bits : UInt64) -> UInt64 {
  if is_nan_bits(bits) {
    0x7ff8000000000000UL
  } else {
    bits
  }
}

///|
/// Read the raw sign bit, including NaN signs.
pub fn is_sign_minus_bits(bits : UInt64) -> Bool {
  (bits & 0x8000000000000000UL) != 0UL
}

///|
/// Subnormal encoding: zero exponent and nonzero fraction.
pub fn is_subnormal_bits(bits : UInt64) -> Bool {
  (bits & 0x7ff0000000000000UL) == 0UL && (bits & 0xfffffffffffffUL) != 0UL
}

///|
/// Finite encoding: exponent is not all ones.
pub fn is_finite_bits(bits : UInt64) -> Bool {
  (bits & 0x7ff0000000000000UL) != 0x7ff0000000000000UL
}

///|
/// Zero encoding, ignoring the sign bit.
pub fn is_zero_bits(bits : UInt64) -> Bool {
  (bits & 0x7fffffffffffffffUL) == 0UL
}

///|
/// Copy only the raw sign bit; no floating-point materialization or rounding.
pub fn copy_sign_bits(magnitude : UInt64, sign : UInt64) -> UInt64 {
  (magnitude & 0x7fffffffffffffffUL) | (sign & 0x8000000000000000UL)
}

///|
/// Toggle only the raw sign bit; NaN payload and signaling status are preserved.
pub fn negate_bits(bits : UInt64) -> UInt64 {
  bits ^ 0x8000000000000000UL
}

///|
/// Clear only the raw sign bit; NaN payload and signaling status are preserved.
pub fn abs_bits(bits : UInt64) -> UInt64 {
  bits & 0x7fffffffffffffffUL
}

///|
/// Return integer payload bits excluding the quiet bit; non-NaNs return None.
/// This is an encoding API, not IEEE getPayload's floating-point result API.
pub fn get_payload_bits(bits : UInt64) -> UInt64? {
  if is_nan_bits(bits) {
    Some(bits & 0x7ffffffffffffUL)
  } else {
    None
  }
}

///|
/// Build a quiet NaN encoding. Reject payloads wider than 51 bits.
/// A zero quiet payload is valid. No existing float value is modified.
pub fn set_payload_bits(
  payload : UInt64,
  sign_minus? : Bool = false,
) -> UInt64? {
  if payload > 0x7ffffffffffffUL {
    None
  } else {
    Some(
      0x7ff8000000000000UL |
      payload |
      (if sign_minus { 0x8000000000000000UL } else { 0UL }),
    )
  }
}

///|
/// Build a signaling NaN encoding; reject zero payload (which would encode infinity).
pub fn set_payload_signaling_bits(
  payload : UInt64,
  sign_minus? : Bool = false,
) -> UInt64? {
  if payload == 0UL || payload > 0x7ffffffffffffUL {
    None
  } else {
    Some(
      0x7ff0000000000000UL |
      payload |
      (if sign_minus { 0x8000000000000000UL } else { 0UL }),
    )
  }
}

///|
/// Portable numeric view: any NaN is mapped to one quiet encoding.
/// Never use this to recover the input NaN sign, payload or signaling status.
pub fn to_bits_canonical(x : Double) -> UInt64 {
  if x != x {
    0x7ff8000000000000UL
  } else {
    x.reinterpret_as_uint64()
  }
}

///|
/// Canonicalize NaNs; finite values, infinities and both zero signs remain unchanged.
pub fn canonicalize_nan(x : Double) -> Double {
  to_bits_canonical(x).reinterpret_as_double()
}

///|
/// Classify the portable numeric view. Use classify_bits for signaling/payload-sensitive input.
pub fn classify(x : Double) -> Classification {
  classify_bits(to_bits_canonical(x))
}

///|
/// Read sign from the portable numeric view (NaN has positive canonical sign).
pub fn is_sign_minus(x : Double) -> Bool {
  is_sign_minus_bits(to_bits_canonical(x))
}

///|
/// Numeric signaling state is intentionally not observable across backends.
pub fn is_signaling(x : Double) -> Bool {
  ignore(x)
  false
}

///|
/// The numeric view is canonicalized before this predicate is evaluated.
pub fn is_canonical(x : Double) -> Bool {
  is_canonical_bits(to_bits_canonical(x))
}

///|
/// Test the portable numeric view for subnormal values.
pub fn is_subnormal(x : Double) -> Bool {
  is_subnormal_bits(to_bits_canonical(x))
}

///|
/// Test the portable numeric view for finite values.
pub fn is_finite(x : Double) -> Bool {
  is_finite_bits(to_bits_canonical(x))
}

///|
/// Test for either signed zero.
pub fn is_zero(x : Double) -> Bool {
  is_zero_bits(to_bits_canonical(x))
}

///|
/// Copy a numeric sign without arithmetic. NaN inputs use positive canonical sign;
/// a NaN magnitude returns canonical NaN. Use copy_sign_bits for full encodings.
pub fn copy_sign(magnitude : Double, sign : Double) -> Double {
  canonicalize_nan_bits(
    copy_sign_bits(to_bits_canonical(magnitude), to_bits_canonical(sign)),
  ).reinterpret_as_double()
}

///|
/// Toggle numeric sign by bits; NaN results are canonicalized.
pub fn negate(x : Double) -> Double {
  canonicalize_nan_bits(negate_bits(to_bits_canonical(x))).reinterpret_as_double()
}

///|
/// Clear numeric sign by bits; NaN results are canonicalized.
pub fn abs(x : Double) -> Double {
  abs_bits(to_bits_canonical(x)).reinterpret_as_double()
}

///|
/// The radix of both supported binary interchange formats.
pub fn radix() -> Int {
  2
}
