///|
test "binary32 fma rounds once, not through binary64" {
  // 2^24 + 1 is not a binary32 value; (2^12 + 1)(2^12 - 1) + 2^-30 forces a sticky bit.
  assert_eq(fma(2.0F, 3.0F, 1.0F), 7.0F)
  assert_eq(fma_bits(0x3f800000U, 0x3f800000U, 0xbf800000U), 0U)
  assert_eq(
    fma_bits_with(
      0x3f800000U,
      0x3f800000U,
      0xbf800000U,
      @binary64.TowardNegative,
    ),
    0x80000000U,
  )
  assert_eq(fma_bits(0x7f7fffffU, 0x40000000U, 0U), 0x7f800000U)
  assert_eq(fma_bits(0x7f800000U, 0U, 0x3f800000U), 0x7fc00000U)
}
