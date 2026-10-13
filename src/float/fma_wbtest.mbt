///|
test "fma rounds the exact product-sum once" {
  // (1 + 2^-27)(1 - 2^-27) - 1 = -2^-54 exactly; a separate multiply and add gives 0.
  let a = 0x3ff0000002000000UL
  let b = 0x3feffffffc000000UL
  let minus_one = 0xbff0000000000000UL
  assert_eq(fma_bits(a, b, minus_one), 0xbc90000000000000UL)
  assert_eq(fma(2.0, 3.0, 1.0), 7.0)
  // 0.1 * 10 + (-1) shows the product error that a plain multiply loses.
  assert_eq(to_bits_canonical(fma(0.1, 10.0, -1.0)), 0x3c90000000000000UL)
}

///|
test "fma zero signs, infinities and NaNs" {
  let one = 0x3ff0000000000000UL
  let minus_one = 0xbff0000000000000UL
  assert_eq(fma_bits(one, one, minus_one), 0UL)
  assert_eq(
    fma_bits_with(one, one, minus_one, TowardNegative),
    0x8000000000000000UL,
  )
  assert_eq(fma_bits(0x8000000000000000UL, one, 0UL), 0UL)
  assert_eq(
    fma_bits(0x8000000000000000UL, one, 0x8000000000000000UL),
    0x8000000000000000UL,
  )
  assert_eq(fma_bits(0UL, 0x7ff0000000000000UL, one), 0x7ff8000000000000UL)
  assert_eq(
    fma_bits(0x7ff0000000000000UL, one, 0xfff0000000000000UL),
    0x7ff8000000000000UL,
  )
  assert_eq(fma_bits(one, one, 0x7ff0000000000000UL), 0x7ff0000000000000UL)
  assert_eq(fma_bits(0x7ff0000000000001UL, one, one), 0x7ff8000000000001UL)
  assert_eq(
    fma_bits(0x7fefffffffffffffUL, 0x4000000000000000UL, 0UL),
    0x7ff0000000000000UL,
  )
  assert_eq(
    fma_bits_with(0x7fefffffffffffffUL, 0x4000000000000000UL, 0UL, TowardZero),
    0x7fefffffffffffffUL,
  )
}
