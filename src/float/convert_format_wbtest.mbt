///|
test "binary64 to binary32 rounds once in every direction" {
  // 1 + 2^-24 is exactly halfway between 1 and 1 + 2^-23.
  let half = 0x3ff0000010000000UL
  assert_eq(to_binary32_bits_with(half, TiesToEven), 0x3f800000U)
  assert_eq(to_binary32_bits_with(half, TiesToAway), 0x3f800001U)
  assert_eq(to_binary32_bits_with(half, TowardZero), 0x3f800000U)
  assert_eq(to_binary32_bits_with(half, TowardPositive), 0x3f800001U)
  assert_eq(
    to_binary32_bits_with(half | 0x8000000000000000UL, TowardNegative),
    0xbf800001U,
  )
  // Overflow depends on the direction.
  let big = 0x47f0000000000000UL
  assert_eq(to_binary32_bits_with(big, TiesToEven), 0x7f800000U)
  assert_eq(to_binary32_bits_with(big, TowardZero), 0x7f7fffffU)
  // Gradual underflow: the smallest binary32 subnormal is 2^-149.
  assert_eq(to_binary32_bits(0x36a0000000000000UL), 1U)
  assert_eq(to_binary32_bits_with(0x36a0000000000001UL, TowardNegative), 1U)
  assert_eq(to_binary32_bits(0x3690000000000000UL), 0U)
}

///|
test "NaN payloads survive a widen and narrow round trip" {
  let quiet = 0x7fc12345U
  assert_eq(to_binary32_bits(0x7ff8000000000000UL | (0x12345UL << 29)), quiet)
  assert_eq(to_binary32_bits(0xfff0000000000001UL), 0xffc00000U)
}
