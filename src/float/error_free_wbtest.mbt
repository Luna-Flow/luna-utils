///|
test "two_sum returns the rounding error" {
  let (s, e) = two_sum(1.0e16, 1.0)
  assert_eq(s, 1.0e16)
  assert_eq(e, 1.0)
  let (s2, e2) = two_sum(0.1, 0.2)
  assert_eq(to_bits_canonical(s2), 0x3fd3333333333334UL)
  assert_eq(to_bits_canonical(e2), 0xbc80000000000000UL)
}

///|
test "fast_two_sum matches two_sum when the larger operand comes first" {
  assert_eq(fast_two_sum(1.0e16, 1.0), two_sum(1.0e16, 1.0))
  // a zero error is +0, also for a negative zero operand
  let (_, e) = fast_two_sum(2.0, -0.0)
  assert_eq(to_bits_canonical(e), 0UL)
}

///|
test "two_prod returns the product error and NaN when the product is not finite" {
  let (p, e) = two_prod(0.1, 10.0)
  assert_eq(p, 1.0)
  assert_eq(to_bits_canonical(e), 0x3c90000000000000UL)
  let (inf, nan_error) = two_prod(1.0e300, 1.0e300)
  assert_eq(inf, 1.0 / 0.0)
  assert_true(is_nan(nan_error))
}
