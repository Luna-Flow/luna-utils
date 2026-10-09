///|
/// Classify an uninterpreted IEEE binary32 encoding, preserving all NaN bits.
pub fn classify_bits(bits : UInt) -> @binary64.Classification {
  let e = bits & 0x7f800000U
  let f = bits & 0x7fffffU
  let negative = is_sign_minus_bits(bits)
  if e == 0x7f800000U {
    if f != 0U {
      if (bits & 0x400000U) == 0U {
        @binary64.SignalingNaN
      } else {
        @binary64.QuietNaN
      }
    } else if negative {
      @binary64.NegativeInfinity
    } else {
      @binary64.PositiveInfinity
    }
  } else if e == 0U {
    if f == 0U {
      if negative {
        @binary64.NegativeZero
      } else {
        @binary64.PositiveZero
      }
    } else if negative {
      @binary64.NegativeSubnormal
    } else {
      @binary64.PositiveSubnormal
    }
  } else if negative {
    @binary64.NegativeNormal
  } else {
    @binary64.PositiveNormal
  }
}

///|
/// True exactly for NaN encodings (exponent all ones, nonzero fraction).
pub fn is_nan_bits(bits : UInt) -> Bool {
  (bits & 0x7f800000U) == 0x7f800000U && (bits & 0x7fffffU) != 0U
}

///|
/// Signaling status is meaningful only for raw encodings, before float materialization.
pub fn is_signaling_bits(bits : UInt) -> Bool {
  is_nan_bits(bits) && (bits & 0x400000U) == 0U
}

///|
/// All non-NaN binary encodings are canonical; NaN uses one positive quiet encoding.
pub fn is_canonical_bits(bits : UInt) -> Bool {
  !is_nan_bits(bits) || bits == 0x7fc00000U
}

///|
/// Replace every NaN encoding with the fixed positive quiet NaN.
pub fn canonicalize_nan_bits(bits : UInt) -> UInt {
  if is_nan_bits(bits) {
    0x7fc00000U
  } else {
    bits
  }
}

///|
/// Read the raw sign bit, including NaN signs.
pub fn is_sign_minus_bits(bits : UInt) -> Bool {
  (bits & 0x80000000U) != 0U
}

///|
/// Subnormal encoding: zero exponent and nonzero fraction.
pub fn is_subnormal_bits(bits : UInt) -> Bool {
  (bits & 0x7f800000U) == 0U && (bits & 0x7fffffU) != 0U
}

///|
/// Finite encoding: exponent is not all ones.
pub fn is_finite_bits(bits : UInt) -> Bool {
  (bits & 0x7f800000U) != 0x7f800000U
}

///|
/// Zero encoding, ignoring the sign bit.
pub fn is_zero_bits(bits : UInt) -> Bool {
  (bits & 0x7fffffffU) == 0U
}

///|
/// Copy only the raw sign bit; no floating-point materialization or rounding.
pub fn copy_sign_bits(magnitude : UInt, sign : UInt) -> UInt {
  (magnitude & 0x7fffffffU) | (sign & 0x80000000U)
}

///|
/// Toggle only the raw sign bit; NaN payload and signaling status are preserved.
pub fn negate_bits(bits : UInt) -> UInt {
  bits ^ 0x80000000U
}

///|
/// Clear only the raw sign bit; NaN payload and signaling status are preserved.
pub fn abs_bits(bits : UInt) -> UInt {
  bits & 0x7fffffffU
}

///|
/// Return integer payload bits excluding the quiet bit; non-NaNs return None.
/// This is an encoding API, not IEEE getPayload's floating-point result API.
pub fn get_payload_bits(bits : UInt) -> UInt? {
  if is_nan_bits(bits) {
    Some(bits & 0x3fffffU)
  } else {
    None
  }
}

///|
/// Build a quiet NaN encoding. Reject payloads wider than 22 bits.
/// A zero quiet payload is valid. No existing float value is modified.
pub fn set_payload_bits(payload : UInt, sign_minus? : Bool = false) -> UInt? {
  if payload > 0x3fffffU {
    None
  } else {
    Some(0x7fc00000U | payload | (if sign_minus { 0x80000000U } else { 0U }))
  }
}

///|
/// Build a signaling NaN encoding; reject zero payload (which would encode infinity).
pub fn set_payload_signaling_bits(
  payload : UInt,
  sign_minus? : Bool = false,
) -> UInt? {
  if payload == 0U || payload > 0x3fffffU {
    None
  } else {
    Some(0x7f800000U | payload | (if sign_minus { 0x80000000U } else { 0U }))
  }
}

///|
/// Portable numeric view: any NaN is mapped to one quiet encoding.
/// Never use this to recover the input NaN sign, payload or signaling status.
pub fn to_bits_canonical(x : Float) -> UInt {
  if x != x {
    0x7fc00000U
  } else {
    x.reinterpret_as_uint()
  }
}

///|
/// Canonicalize NaNs; finite values, infinities and both zero signs remain unchanged.
pub fn canonicalize_nan(x : Float) -> Float {
  Float::reinterpret_from_uint(to_bits_canonical(x))
}

///|
/// Classify the portable numeric view. Use classify_bits for signaling/payload-sensitive input.
pub fn classify(x : Float) -> @binary64.Classification {
  classify_bits(to_bits_canonical(x))
}

///|
/// Read sign from the portable numeric view (NaN has positive canonical sign).
pub fn is_sign_minus(x : Float) -> Bool {
  is_sign_minus_bits(to_bits_canonical(x))
}

///|
/// Numeric signaling state is intentionally not observable across backends.
pub fn is_signaling(x : Float) -> Bool {
  ignore(x)
  false
}

///|
/// The numeric view is canonicalized before this predicate is evaluated.
pub fn is_canonical(x : Float) -> Bool {
  is_canonical_bits(to_bits_canonical(x))
}

///|
/// Test the portable numeric view for subnormal values.
pub fn is_subnormal(x : Float) -> Bool {
  is_subnormal_bits(to_bits_canonical(x))
}

///|
/// Test the portable numeric view for finite values.
pub fn is_finite(x : Float) -> Bool {
  is_finite_bits(to_bits_canonical(x))
}

///|
/// Test for either signed zero.
pub fn is_zero(x : Float) -> Bool {
  is_zero_bits(to_bits_canonical(x))
}

///|
/// Copy a numeric sign without arithmetic. NaN inputs use positive canonical sign;
/// a NaN magnitude returns canonical NaN. Use copy_sign_bits for full encodings.
pub fn copy_sign(magnitude : Float, sign : Float) -> Float {
  Float::reinterpret_from_uint(
    canonicalize_nan_bits(
      copy_sign_bits(to_bits_canonical(magnitude), to_bits_canonical(sign)),
    ),
  )
}

///|
/// Toggle numeric sign by bits; NaN results are canonicalized.
pub fn negate(x : Float) -> Float {
  Float::reinterpret_from_uint(
    canonicalize_nan_bits(negate_bits(to_bits_canonical(x))),
  )
}

///|
/// Clear numeric sign by bits; NaN results are canonicalized.
pub fn abs(x : Float) -> Float {
  Float::reinterpret_from_uint(abs_bits(to_bits_canonical(x)))
}

///|
/// The radix of both supported binary interchange formats.
pub fn radix() -> Int {
  2
}
