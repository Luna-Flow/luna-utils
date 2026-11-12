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

///|
test "binary32 two_sum keeps the error exact when s - a overflows (#71)" {
  let a = Float::reinterpret_from_uint(0xfe8df913U)
  let b = Float::reinterpret_from_uint(0x7f7fffffU)
  let (s, e) = two_sum(a, b)
  assert_eq(to_bits_canonical(s), 0x7f390376U)
  assert_eq(to_bits_canonical(e), 0xf3000000U)
  let (s2, e2) = two_sum(b, a)
  assert_eq(to_bits_canonical(s2), 0x7f390376U)
  assert_eq(to_bits_canonical(e2), 0xf3000000U)
}
