///|
test "flags are returned as values and combine" {
  let a = { ..Flags::none(), inexact: true, }
  let b = { ..Flags::none(), overflow: true, inexact: true, }
  assert_eq(a.combine(b), b)
  assert_true(Flags::none().is_empty())
  assert_eq(b.to_bits(), 5)
  assert_eq(Flags::invalid_only().to_bits(), 16)
}

///|
test "fma and scaleB raise overflow, underflow and inexact" {
  let max_finite = 0x7fefffffffffffffUL
  let (inf, f) = fma_bits_flags(
    max_finite,
    0x4000000000000000UL,
    0UL,
    TiesToEven,
  )
  assert_eq(inf, 0x7ff0000000000000UL)
  assert_eq(f, { ..Flags::none(), overflow: true, inexact: true, })
  // 2^-1074 * 0.5 is half the smallest subnormal: tiny and inexact, rounds to zero (ties to even).
  let (z, f2) = scaleb_bits_flags(1UL, -1, TiesToEven)
  assert_eq(z, 0UL)
  assert_eq(f2, { ..Flags::none(), underflow: true, inexact: true, })
  // an exact subnormal result raises nothing
  let (_, f3) = scaleb_bits_flags(0x0010000000000000UL, -1, TiesToEven)
  assert_eq(f3, Flags::none())
}

///|
test "tininess is detected after rounding" {
  // 2^-126 - 2^-152 rounds, with an unbounded exponent, up to 2^-126: not tiny, only inexact.
  let just_below = 0x380fffffff000000UL
  let (r, f) = to_binary32_bits_flags(just_below, TiesToEven)
  assert_eq(r, 0x00800000U)
  assert_eq(f, { ..Flags::none(), inexact: true, })
  // further below the rounded value is still subnormal: underflow
  let (_, f2) = to_binary32_bits_flags(0x37e0000000000001UL, TiesToEven)
  assert_true(f2.underflow)
}

///|
test "remainder, logB, roundToIntegralExact and convertToInteger flags" {
  assert_eq(
    remainder_bits_flags(0x7ff0000000000000UL, 0x3ff0000000000000UL).1,
    Flags::invalid_only(),
  )
  assert_eq(
    remainder_bits_flags(0x3ff0000000000000UL, 0UL).1,
    Flags::invalid_only(),
  )
  assert_eq(
    remainder_bits_flags(0x4014000000000000UL, 0x4000000000000000UL).1,
    Flags::none(),
  )
  assert_eq(logb_flags(0.0).1, { ..Flags::none(), divide_by_zero: true, })
  assert_eq(
    logb_bits_flags(0x7ff0000000000000UL),
    (None, Flags::invalid_only()),
  )
  let (r, f) = round_to_integral_bits_flags(
    0x3ff8000000000000UL,
    TowardZero,
    exact=true,
  )
  assert_eq(r, 0x3ff0000000000000UL)
  assert_eq(f, { ..Flags::none(), inexact: true, })
  assert_eq(
    round_to_integral_bits_flags(0x3ff8000000000000UL, TowardZero).1,
    Flags::none(),
  )
  assert_eq(
    to_int_flags(2.5, TiesToEven, exact=true),
    (Some(2), { ..Flags::none(), inexact: true, }),
  )
  assert_eq(to_int_flags(2.5, TiesToEven), (Some(2), Flags::none()))
  assert_eq(to_int_flags(1.0e10, TiesToEven), (None, Flags::invalid_only()))
  assert_eq(to_uint_flags(-0.5, TowardNegative), (None, Flags::invalid_only()))
}
