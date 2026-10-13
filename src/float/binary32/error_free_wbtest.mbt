///|
test "binary32 error-free transformations" {
  let (s, e) = two_sum(16777216.0F, 1.0F)
  assert_eq(s, 16777216.0F)
  assert_eq(e, 1.0F)
  let (p, ep) = two_prod(0.1F, 10.0F)
  assert_eq(p, 1.0F)
  assert_true(ep != 0.0F)
  let (_, nan_error) = two_sum(3.0e38F, 3.0e38F)
  assert_true(is_nan(nan_error))
}
