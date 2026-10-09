///|
test "classification boundaries and numeric normalization" {
  assert_eq(classify_bits(0x0UL), PositiveZero)
  assert_eq(classify(0x0UL.reinterpret_as_double()), PositiveZero)
  assert_eq(is_signaling_bits(0x0UL), false)
  assert_eq(is_zero_bits(0x0UL), true)
  assert_eq(is_finite_bits(0x0UL), true)
  assert_eq(is_subnormal_bits(0x0UL), false)
  assert_eq(classify_bits(0x8000000000000000UL), NegativeZero)
  assert_eq(
    classify(0x8000000000000000UL.reinterpret_as_double()),
    NegativeZero,
  )
  assert_eq(is_signaling_bits(0x8000000000000000UL), false)
  assert_eq(is_zero_bits(0x8000000000000000UL), true)
  assert_eq(is_finite_bits(0x8000000000000000UL), true)
  assert_eq(is_subnormal_bits(0x8000000000000000UL), false)
  assert_eq(classify_bits(0x1UL), PositiveSubnormal)
  assert_eq(classify(0x1UL.reinterpret_as_double()), PositiveSubnormal)
  assert_eq(is_signaling_bits(0x1UL), false)
  assert_eq(is_zero_bits(0x1UL), false)
  assert_eq(is_finite_bits(0x1UL), true)
  assert_eq(is_subnormal_bits(0x1UL), true)
  assert_eq(classify_bits(0x800fffffffffffffUL), NegativeSubnormal)
  assert_eq(
    classify(0x800fffffffffffffUL.reinterpret_as_double()),
    NegativeSubnormal,
  )
  assert_eq(is_signaling_bits(0x800fffffffffffffUL), false)
  assert_eq(is_zero_bits(0x800fffffffffffffUL), false)
  assert_eq(is_finite_bits(0x800fffffffffffffUL), true)
  assert_eq(is_subnormal_bits(0x800fffffffffffffUL), true)
  assert_eq(classify_bits(0x10000000000000UL), PositiveNormal)
  assert_eq(
    classify(0x10000000000000UL.reinterpret_as_double()),
    PositiveNormal,
  )
  assert_eq(is_signaling_bits(0x10000000000000UL), false)
  assert_eq(is_zero_bits(0x10000000000000UL), false)
  assert_eq(is_finite_bits(0x10000000000000UL), true)
  assert_eq(is_subnormal_bits(0x10000000000000UL), false)
  assert_eq(classify_bits(0x8010000000000000UL), NegativeNormal)
  assert_eq(
    classify(0x8010000000000000UL.reinterpret_as_double()),
    NegativeNormal,
  )
  assert_eq(is_signaling_bits(0x8010000000000000UL), false)
  assert_eq(is_zero_bits(0x8010000000000000UL), false)
  assert_eq(is_finite_bits(0x8010000000000000UL), true)
  assert_eq(is_subnormal_bits(0x8010000000000000UL), false)
  assert_eq(classify_bits(0x7ff0000000000000UL), PositiveInfinity)
  assert_eq(
    classify(0x7ff0000000000000UL.reinterpret_as_double()),
    PositiveInfinity,
  )
  assert_eq(is_signaling_bits(0x7ff0000000000000UL), false)
  assert_eq(is_zero_bits(0x7ff0000000000000UL), false)
  assert_eq(is_finite_bits(0x7ff0000000000000UL), false)
  assert_eq(is_subnormal_bits(0x7ff0000000000000UL), false)
  assert_eq(classify_bits(0xfff0000000000000UL), NegativeInfinity)
  assert_eq(
    classify(0xfff0000000000000UL.reinterpret_as_double()),
    NegativeInfinity,
  )
  assert_eq(is_signaling_bits(0xfff0000000000000UL), false)
  assert_eq(is_zero_bits(0xfff0000000000000UL), false)
  assert_eq(is_finite_bits(0xfff0000000000000UL), false)
  assert_eq(is_subnormal_bits(0xfff0000000000000UL), false)
  assert_eq(classify_bits(0x7ff0000000000001UL), SignalingNaN)
  assert_eq(classify(0x7ff0000000000001UL.reinterpret_as_double()), QuietNaN)
  assert_eq(is_signaling_bits(0x7ff0000000000001UL), true)
  assert_eq(is_zero_bits(0x7ff0000000000001UL), false)
  assert_eq(is_finite_bits(0x7ff0000000000001UL), false)
  assert_eq(is_subnormal_bits(0x7ff0000000000001UL), false)
  assert_eq(classify_bits(0xfff0000000000001UL), SignalingNaN)
  assert_eq(classify(0xfff0000000000001UL.reinterpret_as_double()), QuietNaN)
  assert_eq(is_signaling_bits(0xfff0000000000001UL), true)
  assert_eq(is_zero_bits(0xfff0000000000001UL), false)
  assert_eq(is_finite_bits(0xfff0000000000001UL), false)
  assert_eq(is_subnormal_bits(0xfff0000000000001UL), false)
  assert_eq(classify_bits(0x7ff8000000000000UL), QuietNaN)
  assert_eq(classify(0x7ff8000000000000UL.reinterpret_as_double()), QuietNaN)
  assert_eq(is_signaling_bits(0x7ff8000000000000UL), false)
  assert_eq(is_zero_bits(0x7ff8000000000000UL), false)
  assert_eq(is_finite_bits(0x7ff8000000000000UL), false)
  assert_eq(is_subnormal_bits(0x7ff8000000000000UL), false)
  assert_eq(classify_bits(0xffffffffffffffffUL), QuietNaN)
  assert_eq(classify(0xffffffffffffffffUL.reinterpret_as_double()), QuietNaN)
  assert_eq(is_signaling_bits(0xffffffffffffffffUL), false)
  assert_eq(is_zero_bits(0xffffffffffffffffUL), false)
  assert_eq(is_finite_bits(0xffffffffffffffffUL), false)
  assert_eq(is_subnormal_bits(0xffffffffffffffffUL), false)
  assert_eq(radix(), 2)
}

///|
test "sign involutions payload boundaries and canonicalization" {
  assert_eq(negate_bits(negate_bits(0x0UL)), 0x0UL)
  assert_eq(abs_bits(0x0UL), 0x0UL)
  assert_eq(copy_sign_bits(0x0UL, 0x8000000000000000UL), 0x8000000000000000UL)
  assert_eq(canonicalize_nan_bits(0x0UL), 0x0UL)
  assert_eq(is_canonical_bits(0x0UL), true)
  assert_eq(
    to_bits_canonical(canonicalize_nan(0x0UL.reinterpret_as_double())),
    0x0UL,
  )
  assert_eq(negate_bits(negate_bits(0x1UL)), 0x1UL)
  assert_eq(abs_bits(0x1UL), 0x1UL)
  assert_eq(copy_sign_bits(0x1UL, 0x8000000000000000UL), 0x8000000000000001UL)
  assert_eq(canonicalize_nan_bits(0x1UL), 0x1UL)
  assert_eq(is_canonical_bits(0x1UL), true)
  assert_eq(
    to_bits_canonical(canonicalize_nan(0x1UL.reinterpret_as_double())),
    0x1UL,
  )
  assert_eq(negate_bits(negate_bits(0xfffffffffffffUL)), 0xfffffffffffffUL)
  assert_eq(abs_bits(0xfffffffffffffUL), 0xfffffffffffffUL)
  assert_eq(
    copy_sign_bits(0xfffffffffffffUL, 0x8000000000000000UL),
    0x800fffffffffffffUL,
  )
  assert_eq(canonicalize_nan_bits(0xfffffffffffffUL), 0xfffffffffffffUL)
  assert_eq(is_canonical_bits(0xfffffffffffffUL), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(0xfffffffffffffUL.reinterpret_as_double()),
    ),
    0xfffffffffffffUL,
  )
  assert_eq(negate_bits(negate_bits(0x10000000000000UL)), 0x10000000000000UL)
  assert_eq(abs_bits(0x10000000000000UL), 0x10000000000000UL)
  assert_eq(
    copy_sign_bits(0x10000000000000UL, 0x8000000000000000UL),
    0x8010000000000000UL,
  )
  assert_eq(canonicalize_nan_bits(0x10000000000000UL), 0x10000000000000UL)
  assert_eq(is_canonical_bits(0x10000000000000UL), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(0x10000000000000UL.reinterpret_as_double()),
    ),
    0x10000000000000UL,
  )
  assert_eq(
    negate_bits(negate_bits(0x7fefffffffffffffUL)),
    0x7fefffffffffffffUL,
  )
  assert_eq(abs_bits(0x7fefffffffffffffUL), 0x7fefffffffffffffUL)
  assert_eq(
    copy_sign_bits(0x7fefffffffffffffUL, 0x8000000000000000UL),
    0xffefffffffffffffUL,
  )
  assert_eq(canonicalize_nan_bits(0x7fefffffffffffffUL), 0x7fefffffffffffffUL)
  assert_eq(is_canonical_bits(0x7fefffffffffffffUL), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(0x7fefffffffffffffUL.reinterpret_as_double()),
    ),
    0x7fefffffffffffffUL,
  )
  assert_eq(
    negate_bits(negate_bits(0x7ff0000000000000UL)),
    0x7ff0000000000000UL,
  )
  assert_eq(abs_bits(0x7ff0000000000000UL), 0x7ff0000000000000UL)
  assert_eq(
    copy_sign_bits(0x7ff0000000000000UL, 0x8000000000000000UL),
    0xfff0000000000000UL,
  )
  assert_eq(canonicalize_nan_bits(0x7ff0000000000000UL), 0x7ff0000000000000UL)
  assert_eq(is_canonical_bits(0x7ff0000000000000UL), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(0x7ff0000000000000UL.reinterpret_as_double()),
    ),
    0x7ff0000000000000UL,
  )
  assert_eq(
    negate_bits(negate_bits(0x7ff0000000000001UL)),
    0x7ff0000000000001UL,
  )
  assert_eq(abs_bits(0x7ff0000000000001UL), 0x7ff0000000000001UL)
  assert_eq(
    copy_sign_bits(0x7ff0000000000001UL, 0x8000000000000000UL),
    0xfff0000000000001UL,
  )
  assert_eq(canonicalize_nan_bits(0x7ff0000000000001UL), 0x7ff8000000000000UL)
  assert_eq(is_canonical_bits(0x7ff0000000000001UL), false)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(0x7ff0000000000001UL.reinterpret_as_double()),
    ),
    0x7ff8000000000000UL,
  )
  assert_eq(
    negate_bits(negate_bits(0x7ff8000000000000UL)),
    0x7ff8000000000000UL,
  )
  assert_eq(abs_bits(0x7ff8000000000000UL), 0x7ff8000000000000UL)
  assert_eq(
    copy_sign_bits(0x7ff8000000000000UL, 0x8000000000000000UL),
    0xfff8000000000000UL,
  )
  assert_eq(canonicalize_nan_bits(0x7ff8000000000000UL), 0x7ff8000000000000UL)
  assert_eq(is_canonical_bits(0x7ff8000000000000UL), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(0x7ff8000000000000UL.reinterpret_as_double()),
    ),
    0x7ff8000000000000UL,
  )
  assert_eq(
    negate_bits(negate_bits(0x7fffffffffffffffUL)),
    0x7fffffffffffffffUL,
  )
  assert_eq(abs_bits(0x7fffffffffffffffUL), 0x7fffffffffffffffUL)
  assert_eq(
    copy_sign_bits(0x7fffffffffffffffUL, 0x8000000000000000UL),
    0xffffffffffffffffUL,
  )
  assert_eq(canonicalize_nan_bits(0x7fffffffffffffffUL), 0x7ff8000000000000UL)
  assert_eq(is_canonical_bits(0x7fffffffffffffffUL), false)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(0x7fffffffffffffffUL.reinterpret_as_double()),
    ),
    0x7ff8000000000000UL,
  )
  assert_eq(
    negate_bits(negate_bits(0x8000000000000000UL)),
    0x8000000000000000UL,
  )
  assert_eq(abs_bits(0x8000000000000000UL), 0x0UL)
  assert_eq(
    copy_sign_bits(0x8000000000000000UL, 0x8000000000000000UL),
    0x8000000000000000UL,
  )
  assert_eq(canonicalize_nan_bits(0x8000000000000000UL), 0x8000000000000000UL)
  assert_eq(is_canonical_bits(0x8000000000000000UL), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(0x8000000000000000UL.reinterpret_as_double()),
    ),
    0x8000000000000000UL,
  )
  assert_eq(
    negate_bits(negate_bits(0x8000000000000001UL)),
    0x8000000000000001UL,
  )
  assert_eq(abs_bits(0x8000000000000001UL), 0x1UL)
  assert_eq(
    copy_sign_bits(0x8000000000000001UL, 0x8000000000000000UL),
    0x8000000000000001UL,
  )
  assert_eq(canonicalize_nan_bits(0x8000000000000001UL), 0x8000000000000001UL)
  assert_eq(is_canonical_bits(0x8000000000000001UL), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(0x8000000000000001UL.reinterpret_as_double()),
    ),
    0x8000000000000001UL,
  )
  assert_eq(
    negate_bits(negate_bits(0xfff0000000000000UL)),
    0xfff0000000000000UL,
  )
  assert_eq(abs_bits(0xfff0000000000000UL), 0x7ff0000000000000UL)
  assert_eq(
    copy_sign_bits(0xfff0000000000000UL, 0x8000000000000000UL),
    0xfff0000000000000UL,
  )
  assert_eq(canonicalize_nan_bits(0xfff0000000000000UL), 0xfff0000000000000UL)
  assert_eq(is_canonical_bits(0xfff0000000000000UL), true)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(0xfff0000000000000UL.reinterpret_as_double()),
    ),
    0xfff0000000000000UL,
  )
  assert_eq(
    negate_bits(negate_bits(0xffffffffffffffffUL)),
    0xffffffffffffffffUL,
  )
  assert_eq(abs_bits(0xffffffffffffffffUL), 0x7fffffffffffffffUL)
  assert_eq(
    copy_sign_bits(0xffffffffffffffffUL, 0x8000000000000000UL),
    0xffffffffffffffffUL,
  )
  assert_eq(canonicalize_nan_bits(0xffffffffffffffffUL), 0x7ff8000000000000UL)
  assert_eq(is_canonical_bits(0xffffffffffffffffUL), false)
  assert_eq(
    to_bits_canonical(
      canonicalize_nan(0xffffffffffffffffUL.reinterpret_as_double()),
    ),
    0x7ff8000000000000UL,
  )
  assert_eq(get_payload_bits(0x7ff0000000000000UL), None)
  assert_eq(get_payload_bits(0x7ff8000000000000UL), Some(0x0UL))
  assert_eq(get_payload_bits(0xffffffffffffffffUL), Some(0x7ffffffffffffUL))
  assert_eq(set_payload_bits(0x0UL), Some(0x7ff8000000000000UL))
  assert_eq(
    set_payload_bits(0x7ffffffffffffUL, sign_minus=true),
    Some(0xffffffffffffffffUL),
  )
  assert_eq(set_payload_bits(0x8000000000000UL), None)
  assert_eq(set_payload_signaling_bits(0x0UL), None)
  assert_eq(set_payload_signaling_bits(0x8000000000000UL), None)
  assert_eq(
    set_payload_signaling_bits(0x1UL, sign_minus=true),
    Some(0xfff0000000000001UL),
  )
}

///|
test "numeric zero sign and exceptional inputs" {
  let negative_zero = 0x8000000000000000UL.reinterpret_as_double()
  assert_eq(to_bits_canonical(negate(negative_zero)), 0x0UL)
  assert_eq(to_bits_canonical(abs(negative_zero)), 0x0UL)
  assert_eq(
    to_bits_canonical(copy_sign(0x0UL.reinterpret_as_double(), negative_zero)),
    0x8000000000000000UL,
  )
  let nan = 0x7ff8000000000000UL.reinterpret_as_double()
  assert_true(canonicalize_nan(nan) != canonicalize_nan(nan))
  assert_eq(classify(negate(nan)), QuietNaN)
  assert_false(is_sign_minus(nan))
  assert_false(is_finite(nan))
  assert_false(is_zero(nan))
  assert_false(is_subnormal(nan))
  assert_false(is_signaling(nan))
  assert_true(is_canonical(nan))
}
