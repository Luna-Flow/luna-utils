///|
test "classification boundaries and numeric normalization" {
  assert_eq(classify_bits(0x0U), @binary64.PositiveZero)
  assert_eq(
    portable_classify(Float::reinterpret_from_uint(0x0U)),
    @binary64.PositiveZero,
  )
  assert_eq(is_signaling_bits(0x0U), false)
  assert_eq(is_zero_bits(0x0U), true)
  assert_eq(is_finite_bits(0x0U), true)
  assert_eq(is_subnormal_bits(0x0U), false)
  assert_eq(classify_bits(0x80000000U), @binary64.NegativeZero)
  assert_eq(
    portable_classify(Float::reinterpret_from_uint(0x80000000U)),
    @binary64.NegativeZero,
  )
  assert_eq(is_signaling_bits(0x80000000U), false)
  assert_eq(is_zero_bits(0x80000000U), true)
  assert_eq(is_finite_bits(0x80000000U), true)
  assert_eq(is_subnormal_bits(0x80000000U), false)
  assert_eq(classify_bits(0x1U), @binary64.PositiveSubnormal)
  assert_eq(
    portable_classify(Float::reinterpret_from_uint(0x1U)),
    @binary64.PositiveSubnormal,
  )
  assert_eq(is_signaling_bits(0x1U), false)
  assert_eq(is_zero_bits(0x1U), false)
  assert_eq(is_finite_bits(0x1U), true)
  assert_eq(is_subnormal_bits(0x1U), true)
  assert_eq(classify_bits(0x807fffffU), @binary64.NegativeSubnormal)
  assert_eq(
    portable_classify(Float::reinterpret_from_uint(0x807fffffU)),
    @binary64.NegativeSubnormal,
  )
  assert_eq(is_signaling_bits(0x807fffffU), false)
  assert_eq(is_zero_bits(0x807fffffU), false)
  assert_eq(is_finite_bits(0x807fffffU), true)
  assert_eq(is_subnormal_bits(0x807fffffU), true)
  assert_eq(classify_bits(0x800000U), @binary64.PositiveNormal)
  assert_eq(
    portable_classify(Float::reinterpret_from_uint(0x800000U)),
    @binary64.PositiveNormal,
  )
  assert_eq(is_signaling_bits(0x800000U), false)
  assert_eq(is_zero_bits(0x800000U), false)
  assert_eq(is_finite_bits(0x800000U), true)
  assert_eq(is_subnormal_bits(0x800000U), false)
  assert_eq(classify_bits(0x80800000U), @binary64.NegativeNormal)
  assert_eq(
    portable_classify(Float::reinterpret_from_uint(0x80800000U)),
    @binary64.NegativeNormal,
  )
  assert_eq(is_signaling_bits(0x80800000U), false)
  assert_eq(is_zero_bits(0x80800000U), false)
  assert_eq(is_finite_bits(0x80800000U), true)
  assert_eq(is_subnormal_bits(0x80800000U), false)
  assert_eq(classify_bits(0x7f800000U), @binary64.PositiveInfinity)
  assert_eq(
    portable_classify(Float::reinterpret_from_uint(0x7f800000U)),
    @binary64.PositiveInfinity,
  )
  assert_eq(is_signaling_bits(0x7f800000U), false)
  assert_eq(is_zero_bits(0x7f800000U), false)
  assert_eq(is_finite_bits(0x7f800000U), false)
  assert_eq(is_subnormal_bits(0x7f800000U), false)
  assert_eq(classify_bits(0xff800000U), @binary64.NegativeInfinity)
  assert_eq(
    portable_classify(Float::reinterpret_from_uint(0xff800000U)),
    @binary64.NegativeInfinity,
  )
  assert_eq(is_signaling_bits(0xff800000U), false)
  assert_eq(is_zero_bits(0xff800000U), false)
  assert_eq(is_finite_bits(0xff800000U), false)
  assert_eq(is_subnormal_bits(0xff800000U), false)
  assert_eq(classify_bits(0x7f800001U), @binary64.SignalingNaN)
  assert_eq(
    portable_classify(Float::reinterpret_from_uint(0x7f800001U)),
    @binary64.QuietNaN,
  )
  assert_eq(is_signaling_bits(0x7f800001U), true)
  assert_eq(is_zero_bits(0x7f800001U), false)
  assert_eq(is_finite_bits(0x7f800001U), false)
  assert_eq(is_subnormal_bits(0x7f800001U), false)
  assert_eq(classify_bits(0xff800001U), @binary64.SignalingNaN)
  assert_eq(
    portable_classify(Float::reinterpret_from_uint(0xff800001U)),
    @binary64.QuietNaN,
  )
  assert_eq(is_signaling_bits(0xff800001U), true)
  assert_eq(is_zero_bits(0xff800001U), false)
  assert_eq(is_finite_bits(0xff800001U), false)
  assert_eq(is_subnormal_bits(0xff800001U), false)
  assert_eq(classify_bits(0x7fc00000U), @binary64.QuietNaN)
  assert_eq(
    portable_classify(Float::reinterpret_from_uint(0x7fc00000U)),
    @binary64.QuietNaN,
  )
  assert_eq(is_signaling_bits(0x7fc00000U), false)
  assert_eq(is_zero_bits(0x7fc00000U), false)
  assert_eq(is_finite_bits(0x7fc00000U), false)
  assert_eq(is_subnormal_bits(0x7fc00000U), false)
  assert_eq(classify_bits(0xffffffffU), @binary64.QuietNaN)
  assert_eq(
    portable_classify(Float::reinterpret_from_uint(0xffffffffU)),
    @binary64.QuietNaN,
  )
  assert_eq(is_signaling_bits(0xffffffffU), false)
  assert_eq(is_zero_bits(0xffffffffU), false)
  assert_eq(is_finite_bits(0xffffffffU), false)
  assert_eq(is_subnormal_bits(0xffffffffU), false)
  assert_eq(radix(), 2)
}

///|
test "sign involutions payload boundaries and canonicalization" {
  assert_eq(negate_bits(negate_bits(0x0U)), 0x0U)
  assert_eq(abs_bits(0x0U), 0x0U)
  assert_eq(copy_sign_bits(0x0U, 0x80000000U), 0x80000000U)
  assert_eq(canonicalize_nan_bits(0x0U), 0x0U)
  assert_eq(is_canonical_bits(0x0U), true)
  assert_eq(
    to_bits_canonical(canonicalize_nan(Float::reinterpret_from_uint(0x0U))),
    0x0U,
  )
  assert_eq(negate_bits(negate_bits(0x1U)), 0x1U)
  assert_eq(abs_bits(0x1U), 0x1U)
  assert_eq(copy_sign_bits(0x1U, 0x80000000U), 0x80000001U)
  assert_eq(canonicalize_nan_bits(0x1U), 0x1U)
  assert_eq(is_canonical_bits(0x1U), true)
  assert_eq(
    to_bits_canonical(canonicalize_nan(Float::reinterpret_from_uint(0x1U))),
    0x1U,
  )
  assert_eq(negate_bits(negate_bits(0x7fffffU)), 0x7fffffU)
  assert_eq(abs_bits(0x7fffffU), 0x7fffffU)
  assert_eq(copy_sign_bits(0x7fffffU, 0x80000000U), 0x807fffffU)
  assert_eq(canonicalize_nan_bits(0x7fffffU), 0x7fffffU)
  assert_eq(is_canonical_bits(0x7fffffU), true)
  assert_eq(
    to_bits_canonical(canonicalize_nan(Float::reinterpret_from_uint(0x7fffffU))),
    0x7fffffU,
  )
  assert_eq(negate_bits(negate_bits(0x800000U)), 0x800000U)
  assert_eq(abs_bits(0x800000U), 0x800000U)
  assert_eq(copy_sign_bits(0x800000U, 0x80000000U), 0x80800000U)
  assert_eq(canonicalize_nan_bits(0x800000U), 0x800000U)
  assert_eq(is_canonical_bits(0x800000U), true)
  assert_eq(
    to_bits_canonical(canonicalize_nan(Float::reinterpret_from_uint(0x800000U))),
    0x800000U,
  )
  assert_eq(negate_bits(negate_bits(0x7f7fffffU)), 0x7f7fffffU)
  assert_eq(abs_bits(0x7f7fffffU), 0x7f7fffffU)
  assert_eq(copy_sign_bits(0x7f7fffffU, 0x80000000U), 0xff7fffffU)
  assert_eq(canonicalize_nan_bits(0x7f7fffffU), 0x7f7fffffU)
  assert_eq(is_canonical_bits(0x7f7fffffU), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(Float::reinterpret_from_uint(0x7f7fffffU)),
    ),
    0x7f7fffffU,
  )
  assert_eq(negate_bits(negate_bits(0x7f800000U)), 0x7f800000U)
  assert_eq(abs_bits(0x7f800000U), 0x7f800000U)
  assert_eq(copy_sign_bits(0x7f800000U, 0x80000000U), 0xff800000U)
  assert_eq(canonicalize_nan_bits(0x7f800000U), 0x7f800000U)
  assert_eq(is_canonical_bits(0x7f800000U), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(Float::reinterpret_from_uint(0x7f800000U)),
    ),
    0x7f800000U,
  )
  assert_eq(negate_bits(negate_bits(0x7f800001U)), 0x7f800001U)
  assert_eq(abs_bits(0x7f800001U), 0x7f800001U)
  assert_eq(copy_sign_bits(0x7f800001U, 0x80000000U), 0xff800001U)
  assert_eq(canonicalize_nan_bits(0x7f800001U), 0x7fc00000U)
  assert_eq(is_canonical_bits(0x7f800001U), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(Float::reinterpret_from_uint(0x7f800001U)),
    ),
    0x7fc00000U,
  )
  assert_eq(negate_bits(negate_bits(0x7fc00000U)), 0x7fc00000U)
  assert_eq(abs_bits(0x7fc00000U), 0x7fc00000U)
  assert_eq(copy_sign_bits(0x7fc00000U, 0x80000000U), 0xffc00000U)
  assert_eq(canonicalize_nan_bits(0x7fc00000U), 0x7fc00000U)
  assert_eq(is_canonical_bits(0x7fc00000U), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(Float::reinterpret_from_uint(0x7fc00000U)),
    ),
    0x7fc00000U,
  )
  assert_eq(negate_bits(negate_bits(0x7fffffffU)), 0x7fffffffU)
  assert_eq(abs_bits(0x7fffffffU), 0x7fffffffU)
  assert_eq(copy_sign_bits(0x7fffffffU, 0x80000000U), 0xffffffffU)
  assert_eq(canonicalize_nan_bits(0x7fffffffU), 0x7fc00000U)
  assert_eq(is_canonical_bits(0x7fffffffU), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(Float::reinterpret_from_uint(0x7fffffffU)),
    ),
    0x7fc00000U,
  )
  assert_eq(negate_bits(negate_bits(0x80000000U)), 0x80000000U)
  assert_eq(abs_bits(0x80000000U), 0x0U)
  assert_eq(copy_sign_bits(0x80000000U, 0x80000000U), 0x80000000U)
  assert_eq(canonicalize_nan_bits(0x80000000U), 0x80000000U)
  assert_eq(is_canonical_bits(0x80000000U), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(Float::reinterpret_from_uint(0x80000000U)),
    ),
    0x80000000U,
  )
  assert_eq(negate_bits(negate_bits(0x80000001U)), 0x80000001U)
  assert_eq(abs_bits(0x80000001U), 0x1U)
  assert_eq(copy_sign_bits(0x80000001U, 0x80000000U), 0x80000001U)
  assert_eq(canonicalize_nan_bits(0x80000001U), 0x80000001U)
  assert_eq(is_canonical_bits(0x80000001U), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(Float::reinterpret_from_uint(0x80000001U)),
    ),
    0x80000001U,
  )
  assert_eq(negate_bits(negate_bits(0xff800000U)), 0xff800000U)
  assert_eq(abs_bits(0xff800000U), 0x7f800000U)
  assert_eq(copy_sign_bits(0xff800000U, 0x80000000U), 0xff800000U)
  assert_eq(canonicalize_nan_bits(0xff800000U), 0xff800000U)
  assert_eq(is_canonical_bits(0xff800000U), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(Float::reinterpret_from_uint(0xff800000U)),
    ),
    0xff800000U,
  )
  assert_eq(negate_bits(negate_bits(0xffffffffU)), 0xffffffffU)
  assert_eq(abs_bits(0xffffffffU), 0x7fffffffU)
  assert_eq(copy_sign_bits(0xffffffffU, 0x80000000U), 0xffffffffU)
  assert_eq(canonicalize_nan_bits(0xffffffffU), 0x7fc00000U)
  assert_eq(is_canonical_bits(0xffffffffU), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(Float::reinterpret_from_uint(0xffffffffU)),
    ),
    0x7fc00000U,
  )
  assert_eq(get_payload_bits(0x7f800000U), None)
  assert_eq(get_payload_bits(0x7fc00000U), Some(0x0U))
  assert_eq(get_payload_bits(0xffffffffU), Some(0x3fffffU))
  assert_eq(set_payload_bits(0x0U), Some(0x7fc00000U))
  assert_eq(set_payload_bits(0x3fffffU, sign_minus=true), Some(0xffffffffU))
  assert_eq(set_payload_bits(0x400000U), None)
  assert_eq(set_payload_signaling_bits(0x0U), None)
  assert_eq(set_payload_signaling_bits(0x400000U), None)
  assert_eq(
    set_payload_signaling_bits(0x1U, sign_minus=true),
    Some(0xff800001U),
  )
}

///|
test "numeric zero sign and exceptional inputs" {
  let negative_zero = Float::reinterpret_from_uint(0x80000000U)
  assert_eq(to_bits_canonical(portable_negate(negative_zero)), 0x0U)
  assert_eq(to_bits_canonical(portable_abs(negative_zero)), 0x0U)
  assert_eq(
    to_bits_canonical(
      portable_copy_sign(Float::reinterpret_from_uint(0x0U), negative_zero),
    ),
    0x80000000U,
  )
  let nan = Float::reinterpret_from_uint(0x7fc00000U)
  assert_true(canonicalize_nan(nan) != canonicalize_nan(nan))
  assert_eq(portable_classify(portable_negate(nan)), @binary64.QuietNaN)
  assert_false(portable_is_sign_minus(nan))
  assert_false(is_finite(nan))
  assert_false(is_zero(nan))
  assert_false(is_subnormal(nan))
  assert_false(portable_is_signaling(nan))
  assert_true(portable_is_canonical(nan))
}

///|
test "portable sign operations cover finite boundaries and infinities" {
  assert_eq(to_bits_canonical(portable_negate(1.0)), 0xbf800000U)
  assert_eq(
    to_bits_canonical(portable_abs(Float::reinterpret_from_uint(0x80000001U))),
    0x1U,
  )
  assert_eq(
    to_bits_canonical(
      portable_copy_sign(Float::reinterpret_from_uint(0x7f7fffffU), -1.0),
    ),
    0xff7fffffU,
  )
  assert_eq(
    to_bits_canonical(
      portable_negate(Float::reinterpret_from_uint(0x7f800000U)),
    ),
    0xff800000U,
  )
}
