///|
test "relations ignore the sign of zero and treat every NaN as unordered" {
  assert_eq(relation_bits(0UL, 0x8000000000000000UL), Equal)
  assert_eq(relation(-0.0, 0.0), Equal)
  assert_eq(relation_bits(0x7ff0000000000000UL, 0x7ff0000000000000UL), Equal)
  assert_eq(relation_bits(0xfff0000000000000UL, 0x7ff0000000000000UL), Less)
  assert_eq(relation(2.0, 1.0), Greater)
  assert_eq(
    relation_bits(0x7ff8000000000000UL, 0x7ff8000000000000UL),
    Unordered,
  )
  assert_eq(relation_bits(0x7ff0000000000001UL, 1UL), Unordered)
}

///|
test "quiet predicates signal only for signaling NaN operands" {
  let quiet_nan = 0x7ff8000000000000UL
  let signaling_nan = 0x7ff0000000000001UL
  let one = 0x3ff0000000000000UL
  assert_eq(compare_predicate_bits(QuietEqual, quiet_nan, one), (false, false))
  assert_eq(
    compare_predicate_bits(QuietNotEqual, quiet_nan, one),
    (true, false),
  )
  assert_eq(
    compare_predicate_bits(QuietEqual, signaling_nan, one),
    (false, true),
  )
  assert_eq(
    compare_predicate_bits(QuietUnordered, quiet_nan, quiet_nan),
    (true, false),
  )
  assert_eq(compare_predicate_bits(QuietOrdered, one, one), (true, false))
}

///|
test "signaling predicates also signal for quiet NaN operands" {
  let quiet_nan = 0x7ff8000000000000UL
  let one = 0x3ff0000000000000UL
  assert_eq(
    compare_predicate_bits(SignalingLess, quiet_nan, one),
    (false, true),
  )
  assert_eq(
    compare_predicate_bits(SignalingNotLess, quiet_nan, one),
    (true, true),
  )
  assert_eq(
    compare_predicate_bits(SignalingEqual, quiet_nan, one),
    (false, true),
  )
  assert_eq(compare_predicate_bits(SignalingLess, one, one), (false, false))
  assert_eq(compare_predicate(SignalingLessEqual, 1.0, 1.0), (true, false))
  // A numeric NaN cannot tell signaling from quiet, so quiet predicates stay silent.
  assert_eq(compare_predicate(QuietLess, 0.0 / 0.0, 1.0), (false, false))
  assert_eq(compare_predicate(SignalingLess, 0.0 / 0.0, 1.0), (false, true))
}

///|
test "not predicates are not the logical negation of the relation pair" {
  // NOT (x < y) is true for unordered operands while (x >= y) is false.
  let quiet_nan = 0x7ff8000000000000UL
  let one = 0x3ff0000000000000UL
  assert_eq(compare_predicate_bits(SignalingNotLess, quiet_nan, one).0, true)
  assert_eq(
    compare_predicate_bits(SignalingGreaterEqual, quiet_nan, one).0,
    false,
  )
}

///|
test "isInfinite, isNormal and isNaN" {
  assert_true(is_infinite_bits(0xfff0000000000000UL))
  assert_false(is_infinite_bits(0x7ff0000000000001UL))
  assert_true(is_normal_bits(0x0010000000000000UL))
  assert_false(is_normal_bits(0x000fffffffffffffUL))
  assert_false(is_normal_bits(0x7ff0000000000000UL))
  assert_true(is_infinite(1.0 / 0.0))
  assert_true(is_nan(0.0 / 0.0))
  assert_false(is_normal(0.0))
}
