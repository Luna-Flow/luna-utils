///|
test "binary32 relations and predicates" {
  assert_eq(relation_bits(0U, 0x80000000U), @binary64.Equal)
  assert_eq(relation_bits(0x7fc00000U, 1U), @binary64.Unordered)
  assert_eq(
    compare_predicate_bits(@binary64.QuietEqual, 0x7f800001U, 0x3f800000U),
    (false, true),
  )
  assert_eq(
    compare_predicate_bits(@binary64.SignalingLess, 0x7fc00000U, 0x3f800000U),
    (false, true),
  )
  assert_true(is_infinite_bits(0xff800000U))
  assert_true(is_normal_bits(0x00800000U))
  assert_false(is_normal_bits(0x007fffffU))
}
