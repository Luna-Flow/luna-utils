///|
test "binary32 to binary64 is exact" {
  assert_eq(to_binary64_bits(0x3f800000U), 0x3ff0000000000000UL)
  assert_eq(to_binary64_bits(1U), 0x36a0000000000000UL)
  assert_eq(to_binary64_bits(0x007fffffU), 0x380fffffc0000000UL)
  assert_eq(to_binary64_bits(0x80000000U), 0x8000000000000000UL)
  assert_eq(to_binary64_bits(0xff800000U), 0xfff0000000000000UL)
  assert_eq(
    to_binary64_bits(0x7fc12345U),
    0x7ff8000000000000UL | (0x12345UL << 29),
  )
  assert_eq(to_binary64_bits(0x7f800001U), 0x7ff8000000000000UL | (1UL << 29))
}
