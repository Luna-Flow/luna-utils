///|
test "classification boundaries and numeric normalization" {
  assert_eq(classify_bits(0x0UL), PositiveZero)
  assert_eq(portable_classify(0x0UL.reinterpret_as_double()), PositiveZero)
  assert_eq(is_signaling_bits(0x0UL), false)
  assert_eq(is_zero_bits(0x0UL), true)
  assert_eq(is_finite_bits(0x0UL), true)
  assert_eq(is_subnormal_bits(0x0UL), false)
  assert_eq(classify_bits(0x8000000000000000UL), NegativeZero)
  assert_eq(
    portable_classify(0x8000000000000000UL.reinterpret_as_double()),
    NegativeZero,
  )
  assert_eq(is_signaling_bits(0x8000000000000000UL), false)
  assert_eq(is_zero_bits(0x8000000000000000UL), true)
  assert_eq(is_finite_bits(0x8000000000000000UL), true)
  assert_eq(is_subnormal_bits(0x8000000000000000UL), false)
  assert_eq(classify_bits(0x1UL), PositiveSubnormal)
  assert_eq(portable_classify(0x1UL.reinterpret_as_double()), PositiveSubnormal)
  assert_eq(is_signaling_bits(0x1UL), false)
  assert_eq(is_zero_bits(0x1UL), false)
  assert_eq(is_finite_bits(0x1UL), true)
  assert_eq(is_subnormal_bits(0x1UL), true)
  assert_eq(classify_bits(0x800fffffffffffffUL), NegativeSubnormal)
  assert_eq(
    portable_classify(0x800fffffffffffffUL.reinterpret_as_double()),
    NegativeSubnormal,
  )
  assert_eq(is_signaling_bits(0x800fffffffffffffUL), false)
  assert_eq(is_zero_bits(0x800fffffffffffffUL), false)
  assert_eq(is_finite_bits(0x800fffffffffffffUL), true)
  assert_eq(is_subnormal_bits(0x800fffffffffffffUL), true)
  assert_eq(classify_bits(0x10000000000000UL), PositiveNormal)
  assert_eq(
    portable_classify(0x10000000000000UL.reinterpret_as_double()),
    PositiveNormal,
  )
  assert_eq(is_signaling_bits(0x10000000000000UL), false)
  assert_eq(is_zero_bits(0x10000000000000UL), false)
  assert_eq(is_finite_bits(0x10000000000000UL), true)
  assert_eq(is_subnormal_bits(0x10000000000000UL), false)
  assert_eq(classify_bits(0x8010000000000000UL), NegativeNormal)
  assert_eq(
    portable_classify(0x8010000000000000UL.reinterpret_as_double()),
    NegativeNormal,
  )
  assert_eq(is_signaling_bits(0x8010000000000000UL), false)
  assert_eq(is_zero_bits(0x8010000000000000UL), false)
  assert_eq(is_finite_bits(0x8010000000000000UL), true)
  assert_eq(is_subnormal_bits(0x8010000000000000UL), false)
  assert_eq(classify_bits(0x7ff0000000000000UL), PositiveInfinity)
  assert_eq(
    portable_classify(0x7ff0000000000000UL.reinterpret_as_double()),
    PositiveInfinity,
  )
  assert_eq(is_signaling_bits(0x7ff0000000000000UL), false)
  assert_eq(is_zero_bits(0x7ff0000000000000UL), false)
  assert_eq(is_finite_bits(0x7ff0000000000000UL), false)
  assert_eq(is_subnormal_bits(0x7ff0000000000000UL), false)
  assert_eq(classify_bits(0xfff0000000000000UL), NegativeInfinity)
  assert_eq(
    portable_classify(0xfff0000000000000UL.reinterpret_as_double()),
    NegativeInfinity,
  )
  assert_eq(is_signaling_bits(0xfff0000000000000UL), false)
  assert_eq(is_zero_bits(0xfff0000000000000UL), false)
  assert_eq(is_finite_bits(0xfff0000000000000UL), false)
  assert_eq(is_subnormal_bits(0xfff0000000000000UL), false)
  assert_eq(classify_bits(0x7ff0000000000001UL), SignalingNaN)
  assert_eq(
    portable_classify(0x7ff0000000000001UL.reinterpret_as_double()),
    QuietNaN,
  )
  assert_eq(is_signaling_bits(0x7ff0000000000001UL), true)
  assert_eq(is_zero_bits(0x7ff0000000000001UL), false)
  assert_eq(is_finite_bits(0x7ff0000000000001UL), false)
  assert_eq(is_subnormal_bits(0x7ff0000000000001UL), false)
  assert_eq(classify_bits(0xfff0000000000001UL), SignalingNaN)
  assert_eq(
    portable_classify(0xfff0000000000001UL.reinterpret_as_double()),
    QuietNaN,
  )
  assert_eq(is_signaling_bits(0xfff0000000000001UL), true)
  assert_eq(is_zero_bits(0xfff0000000000001UL), false)
  assert_eq(is_finite_bits(0xfff0000000000001UL), false)
  assert_eq(is_subnormal_bits(0xfff0000000000001UL), false)
  assert_eq(classify_bits(0x7ff8000000000000UL), QuietNaN)
  assert_eq(
    portable_classify(0x7ff8000000000000UL.reinterpret_as_double()),
    QuietNaN,
  )
  assert_eq(is_signaling_bits(0x7ff8000000000000UL), false)
  assert_eq(is_zero_bits(0x7ff8000000000000UL), false)
  assert_eq(is_finite_bits(0x7ff8000000000000UL), false)
  assert_eq(is_subnormal_bits(0x7ff8000000000000UL), false)
  assert_eq(classify_bits(0xffffffffffffffffUL), QuietNaN)
  assert_eq(
    portable_classify(0xffffffffffffffffUL.reinterpret_as_double()),
    QuietNaN,
  )
  assert_eq(is_signaling_bits(0xffffffffffffffffUL), false)
  assert_eq(is_zero_bits(0xffffffffffffffffUL), false)
  assert_eq(is_finite_bits(0xffffffffffffffffUL), false)
  assert_eq(is_subnormal_bits(0xffffffffffffffffUL), false)
  assert_eq(radix(), 2)
}

// IEEE 754-2019 §5.9 roundToIntegral: the five directions are exact integral
// results, preserve signed zero, leave infinities unchanged, and quiet NaN.
// Expected table (input -> ties-even, ties-away, toward-zero, toward-positive,
// toward-negative): 2.5 -> 2, 3, 2, 3, 2; -2.5 -> -2, -3, -2, -2, -3.
// nextDown(0.5) -> 0, 0, 0, 1, 0; -0.3 -> -0, -0, -0, -0, -1.
// IEEE 754-2019 §5.9 also requires already integral values in [2^52, 2^53)
// to remain unchanged; NaN is quieted and ±infinity is unchanged.

///|
test "round to integral directions" {
  assert_eq(round_ties_even(2.5), 2.0)
  assert_eq(round_ties_away(2.5), 3.0)
  assert_eq(round_toward_zero(2.5), 2.0)
  assert_eq(round_toward_positive(2.5), 3.0)
  assert_eq(round_toward_negative(2.5), 2.0)
  assert_eq(round_ties_even(-2.5), -2.0)
  assert_eq(round_ties_away(-2.5), -3.0)
  assert_eq(round_toward_zero(-2.5), -2.0)
  assert_eq(round_toward_positive(-2.5), -2.0)
  assert_eq(round_toward_negative(-2.5), -3.0)
  assert_eq(to_bits_canonical(round_ties_even(0.5)), 0x0000000000000000UL)
  assert_eq(to_bits_canonical(round_ties_away(0.5)), 0x3ff0000000000000UL)
  assert_eq(to_bits_canonical(round_ties_even(-0.5)), 0x8000000000000000UL)
  assert_eq(to_bits_canonical(round_ties_away(-0.5)), 0xbff0000000000000UL)
  assert_eq(round_ties_even(0.75), 1.0)
  assert_eq(round_ties_even(-0.75), -1.0)
  let below_half = 0x3fdfffffffffffffUL.reinterpret_as_double()
  assert_eq(round_ties_even(below_half), 0.0)
  assert_eq(round_ties_away(below_half), 0.0)
  assert_eq(round_toward_zero(below_half), 0.0)
  assert_eq(round_toward_positive(below_half), 1.0)
  assert_eq(round_toward_negative(below_half), 0.0)
  let neg_fraction = -0.3
  assert_eq(
    to_bits_canonical(round_ties_even(neg_fraction)),
    0x8000000000000000UL,
  )
  assert_eq(
    to_bits_canonical(round_ties_away(neg_fraction)),
    0x8000000000000000UL,
  )
  assert_eq(
    to_bits_canonical(round_toward_zero(neg_fraction)),
    0x8000000000000000UL,
  )
  assert_eq(
    to_bits_canonical(round_toward_positive(neg_fraction)),
    0x8000000000000000UL,
  )
  assert_eq(
    to_bits_canonical(round_toward_negative(neg_fraction)),
    0xbff0000000000000UL,
  )
  let large = 0x4330000000000001UL.reinterpret_as_double()
  assert_eq(to_bits_canonical(round_ties_even(large)), 0x4330000000000001UL)
  assert_eq(to_bits_canonical(round_ties_away(large)), 0x4330000000000001UL)
  assert_eq(to_bits_canonical(round_toward_zero(large)), 0x4330000000000001UL)
  assert_eq(
    to_bits_canonical(round_toward_positive(large)),
    0x4330000000000001UL,
  )
  assert_eq(
    to_bits_canonical(round_toward_negative(large)),
    0x4330000000000001UL,
  )
  assert_eq(
    to_bits_canonical(
      round_ties_even(0x7ff0000000000001UL.reinterpret_as_double()),
    ),
    0x7ff8000000000000UL,
  )
  assert_eq(
    to_bits_canonical(
      round_ties_even(0x7ff0000000000000UL.reinterpret_as_double()),
    ),
    0x7ff0000000000000UL,
  )
  assert_eq(
    to_bits_canonical(
      round_ties_even(0xfff0000000000000UL.reinterpret_as_double()),
    ),
    0xfff0000000000000UL,
  )
  assert_eq(round_to_integral(2.5, TiesToEven), 2.0)
  assert_eq(round_to_integral(-2.5, TiesToAway), -3.0)
  assert_eq(round_to_integral(2.5, TowardZero), 2.0)
  assert_eq(round_to_integral(2.5, TowardPositive), 3.0)
  assert_eq(round_to_integral(-2.5, TowardNegative), -3.0)
}

///|
test "rounding zero subnormal tie and exponent boundaries" {
  let positive_zero = 0x0UL.reinterpret_as_double()
  let negative_zero = 0x8000000000000000UL.reinterpret_as_double()
  assert_eq(to_bits_canonical(round_ties_even(positive_zero)), 0x0UL)
  assert_eq(to_bits_canonical(round_ties_away(positive_zero)), 0x0UL)
  assert_eq(to_bits_canonical(round_toward_zero(positive_zero)), 0x0UL)
  assert_eq(to_bits_canonical(round_toward_positive(positive_zero)), 0x0UL)
  assert_eq(to_bits_canonical(round_toward_negative(positive_zero)), 0x0UL)
  assert_eq(
    to_bits_canonical(round_ties_even(negative_zero)),
    0x8000000000000000UL,
  )
  assert_eq(
    to_bits_canonical(round_ties_away(negative_zero)),
    0x8000000000000000UL,
  )
  assert_eq(
    to_bits_canonical(round_toward_zero(negative_zero)),
    0x8000000000000000UL,
  )
  assert_eq(
    to_bits_canonical(round_toward_positive(negative_zero)),
    0x8000000000000000UL,
  )
  assert_eq(
    to_bits_canonical(round_toward_negative(negative_zero)),
    0x8000000000000000UL,
  )

  let min_subnormal = 0x1UL.reinterpret_as_double()
  let neg_min_subnormal = 0x8000000000000001UL.reinterpret_as_double()
  let max_subnormal = 0x000fffffffffffffUL.reinterpret_as_double()
  let neg_max_subnormal = 0x800fffffffffffffUL.reinterpret_as_double()
  assert_eq(
    to_bits_canonical(round_toward_positive(min_subnormal)),
    0x3ff0000000000000UL,
  )
  assert_eq(to_bits_canonical(round_toward_negative(min_subnormal)), 0x0UL)
  assert_eq(
    to_bits_canonical(round_toward_negative(neg_min_subnormal)),
    0xbff0000000000000UL,
  )
  assert_eq(
    to_bits_canonical(round_toward_positive(neg_min_subnormal)),
    0x8000000000000000UL,
  )
  assert_eq(
    to_bits_canonical(round_toward_positive(max_subnormal)),
    0x3ff0000000000000UL,
  )
  assert_eq(to_bits_canonical(round_toward_negative(max_subnormal)), 0x0UL)
  assert_eq(
    to_bits_canonical(round_toward_negative(neg_max_subnormal)),
    0xbff0000000000000UL,
  )
  assert_eq(
    to_bits_canonical(round_toward_positive(neg_max_subnormal)),
    0x8000000000000000UL,
  )

  assert_eq(round_ties_even(1.5), 2.0)
  assert_eq(round_ties_even(3.5), 4.0)
  assert_eq(round_ties_even(-1.5), -2.0)
  assert_eq(round_ties_even(-3.5), -4.0)
  assert_eq(round_ties_away(1.5), 2.0)
  assert_eq(round_ties_away(3.5), 4.0)
  assert_eq(round_ties_away(-1.5), -2.0)
  assert_eq(round_ties_away(-3.5), -4.0)

  let below_one = 0x3fefffffffffffffUL.reinterpret_as_double()
  assert_eq(to_bits_canonical(round_ties_even(below_one)), 0x3ff0000000000000UL)
  let exponent_tie = 0x4320000000000001UL.reinterpret_as_double()
  assert_eq(
    to_bits_canonical(round_ties_even(exponent_tie)),
    0x4320000000000000UL,
  )
  assert_eq(
    to_bits_canonical(round_ties_away(exponent_tie)),
    0x4320000000000002UL,
  )
  let boundary_tie = 0x432fffffffffffffUL.reinterpret_as_double()
  assert_eq(
    to_bits_canonical(round_ties_even(boundary_tie)),
    0x4330000000000000UL,
  )
  assert_eq(
    to_bits_canonical(round_ties_away(boundary_tie)),
    0x4330000000000000UL,
  )

  let max_finite = 0x7fefffffffffffffUL.reinterpret_as_double()
  assert_eq(
    to_bits_canonical(round_ties_even(max_finite)),
    0x7fefffffffffffffUL,
  )
  assert_eq(
    to_bits_canonical(round_ties_away(max_finite)),
    0x7fefffffffffffffUL,
  )
  assert_eq(
    to_bits_canonical(round_toward_zero(max_finite)),
    0x7fefffffffffffffUL,
  )
  assert_eq(
    to_bits_canonical(round_toward_positive(max_finite)),
    0x7fefffffffffffffUL,
  )
  assert_eq(
    to_bits_canonical(round_toward_negative(max_finite)),
    0x7fefffffffffffffUL,
  )
  let neg_max_finite = 0xffefffffffffffffUL.reinterpret_as_double()
  assert_eq(
    to_bits_canonical(round_ties_even(neg_max_finite)),
    0xffefffffffffffffUL,
  )
  assert_eq(
    to_bits_canonical(round_toward_positive(neg_max_finite)),
    0xffefffffffffffffUL,
  )

  assert_eq(
    to_bits_canonical(
      round_ties_even(0x7ff8000000000000UL.reinterpret_as_double()),
    ),
    0x7ff8000000000000UL,
  )
  assert_eq(
    to_bits_canonical(
      round_ties_even(0xfff8000000000000UL.reinterpret_as_double()),
    ),
    0x7ff8000000000000UL,
  )
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
  assert_eq(is_canonical_bits(0x7ff0000000000001UL), true)
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
  assert_eq(is_canonical_bits(0x7fffffffffffffffUL), true)
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
  assert_eq(is_canonical_bits(0xffffffffffffffffUL), true)
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
  assert_eq(to_bits_canonical(portable_negate(negative_zero)), 0x0UL)
  assert_eq(to_bits_canonical(portable_abs(negative_zero)), 0x0UL)
  assert_eq(
    to_bits_canonical(
      portable_copy_sign(0x0UL.reinterpret_as_double(), negative_zero),
    ),
    0x8000000000000000UL,
  )
  let nan = 0x7ff8000000000000UL.reinterpret_as_double()
  assert_true(canonicalize_nan(nan) != canonicalize_nan(nan))
  assert_eq(portable_classify(portable_negate(nan)), QuietNaN)
  assert_false(portable_is_sign_minus(nan))
  assert_false(is_finite(nan))
  assert_false(is_zero(nan))
  assert_false(is_subnormal(nan))
  assert_false(portable_is_signaling(nan))
  assert_true(portable_is_canonical(nan))
}

///|
test "portable sign operations cover finite boundaries and infinities" {
  assert_eq(to_bits_canonical(portable_negate(1.0)), 0xbff0000000000000UL)
  assert_eq(
    to_bits_canonical(
      portable_abs(0x8000000000000001UL.reinterpret_as_double()),
    ),
    0x1UL,
  )
  assert_eq(
    to_bits_canonical(
      portable_copy_sign(0x7fefffffffffffffUL.reinterpret_as_double(), -1.0),
    ),
    0xffefffffffffffffUL,
  )
  assert_eq(
    to_bits_canonical(
      portable_negate(0x7ff0000000000000UL.reinterpret_as_double()),
    ),
    0xfff0000000000000UL,
  )
}

///|
// IEEE 754-2019 §9.6: minimum/maximum propagate NaN and select -0/+0
// independently of argument order.
test "minimum and maximum use IEEE edge ordering" {
  assert_eq(to_bits_canonical(minimum(0.0, -0.0)), 0x8000000000000000UL)
  assert_eq(to_bits_canonical(minimum(-0.0, 0.0)), 0x8000000000000000UL)
  assert_eq(to_bits_canonical(maximum(-0.0, 0.0)), 0UL)
  assert_eq(to_bits_canonical(maximum(0.0, -0.0)), 0UL)
  let nan = 0x7ff0000000000042UL.reinterpret_as_double()
  assert_eq(to_bits_canonical(minimum(1.0, nan)), 0x7ff8000000000000UL)
  assert_eq(to_bits_canonical(minimum(nan, 1.0)), 0x7ff8000000000000UL)
  assert_eq(to_bits_canonical(maximum(1.0, nan)), 0x7ff8000000000000UL)
  assert_eq(to_bits_canonical(maximum(nan, 1.0)), 0x7ff8000000000000UL)
  assert_eq(minimum(-1.0, 1.0), -1.0)
  assert_eq(maximum(-1.0, 1.0), 1.0)
}

///|
// IEEE 754-2019 §5.10: negative encodings reverse magnitude order; positive
// encodings ascend. Samples include signed zeros and both NaN classes.
test "total order compares raw encodings and portable values" {
  let ordered = [
    0xffff800000000002UL, 0xffff800000000001UL, 0xffff000000000002UL, 0xffff000000000001UL,
    0xfff0000000000000UL, 0x8000000000000000UL, 0x0000000000000000UL, 0x7ff0000000000000UL,
    0x7ff0000000000001UL, 0x7ff0000000000002UL, 0x7ff8000000000000UL, 0x7ff8000000000001UL,
  ]
  for i in 0..<ordered.length() {
    assert_true(total_order_bits(ordered[i], ordered[i]))
    if i + 1 < ordered.length() {
      assert_true(total_order_bits(ordered[i], ordered[i + 1]))
      assert_false(total_order_bits(ordered[i + 1], ordered[i]))
    }
  }
  assert_true(total_order(-0.0, 0.0))
  assert_false(total_order(0.0, -0.0))
  let nan = 0x7ff0000000000042UL.reinterpret_as_double()
  assert_true(total_order(1.0, nan))
  assert_true(total_order(nan, nan))
}

///|
test "sort total order sorts arrays and mutable views" {
  let values = [
    0x7ff0000000000001UL.reinterpret_as_double(),
    1.0,
    0.0,
    -0.0,
    -1.0,
    0xfff0000000000000UL.reinterpret_as_double(),
    0x7ff0000000000000UL.reinterpret_as_double(),
  ]
  sort_total_order(values)
  assert_eq(to_bits_canonical(values[0]), 0xfff0000000000000UL)
  assert_eq(to_bits_canonical(values[1]), 0xbff0000000000000UL)
  assert_eq(to_bits_canonical(values[2]), 0x8000000000000000UL)
  assert_eq(to_bits_canonical(values[3]), 0UL)
  assert_eq(to_bits_canonical(values[4]), 0x3ff0000000000000UL)
  assert_eq(to_bits_canonical(values[5]), 0x7ff0000000000000UL)
  assert_eq(to_bits_canonical(values[6]), 0x7ff8000000000000UL)
  let view_values = [3.0, -2.0, 1.0]
  sort_total_order_view(view_values.mut_view())
  assert_eq(view_values, [-2.0, 1.0, 3.0])
}
