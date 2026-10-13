///|
test "binary32 nextUp, remainder, scaleB and logB" {
  assert_eq(next_up_bits(0x80000001U), 0x80000000U)
  assert_eq(remainder(5.0F, 2.0F), 1.0F)
  assert_eq(scaleb_bits(0x3f800000U, -149), 1U)
  assert_eq(scaleb_bits(0x3f800000U, -150), 0U)
  assert_eq(logb_bits(1U), Some(-149))
  assert_eq(logb_bits(0x3f800000U), Some(0))
}
