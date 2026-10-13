///|
test "nextUp and nextDown at the edges" {
  assert_eq(next_up_bits(0UL), 1UL)
  assert_eq(next_up_bits(0x8000000000000000UL), 1UL)
  assert_eq(next_up_bits(0x8000000000000001UL), 0x8000000000000000UL)
  assert_eq(next_up_bits(0x7ff0000000000000UL), 0x7ff0000000000000UL)
  assert_eq(next_up_bits(0xfff0000000000000UL), 0xffefffffffffffffUL)
  assert_eq(next_down_bits(0UL), 0x8000000000000001UL)
  assert_eq(next_up_bits(0x7ff0000000000001UL), 0x7ff8000000000001UL)
  assert_eq(to_bits_canonical(next_up(0.0 / 0.0)), 0x7ff8000000000000UL)
}

///|
test "remainder is exact, rounds the quotient to even and keeps the sign of x for zero" {
  // 5 / 2 = 2.5 rounds to the even quotient 2, so the remainder is 1.
  assert_eq(remainder(5.0, 2.0), 1.0)
  // 7 / 2 = 3.5 rounds to 4, so the remainder is -1.
  assert_eq(remainder(7.0, 2.0), -1.0)
  assert_eq(to_bits_canonical(remainder(-4.0, 2.0)), 0x8000000000000000UL)
  assert_eq(remainder(3.0, 1.0 / 0.0), 3.0)
  assert_true(is_nan(remainder(1.0 / 0.0, 2.0)))
  assert_true(is_nan(remainder(1.0, 0.0)))
}

///|
test "scaleB rounds once and logB is the true exponent" {
  assert_eq(scaleb(1.0, 10), 1024.0)
  assert_eq(to_bits_canonical(scaleb(1.0, -1074)), 1UL)
  assert_eq(to_bits_canonical(scaleb(1.0, -1075)), 0UL)
  assert_eq(to_bits_canonical(scaleb(1.0, 1024)), 0x7ff0000000000000UL)
  assert_eq(scaleb_bits_with(0x3ff8000000000000UL, -1075, TowardPositive), 1UL)
  assert_eq(logb_bits(1UL), Some(-1074))
  assert_eq(logb_bits(0x3ff0000000000000UL), Some(0))
  assert_eq(logb_bits(0x7ff0000000000000UL), None)
  assert_eq(logb(0.0), -1.0 / 0.0)
  assert_eq(logb(8.0), 3.0)
}
