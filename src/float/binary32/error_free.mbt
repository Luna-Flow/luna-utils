///|
/// Error-free sum (Knuth's TwoSum): returns `(s, e)` with `s` the sum rounded to nearest even
/// and `e` the rounding error, so that `a + b == s + e` exactly when `a`, `b` and `s` are
/// finite. If `s` is not finite (an infinite or NaN operand, or overflow) `e` is the quiet NaN.
/// It needs no assumption on the order of `a` and `b`.
pub fn two_sum(a : Float, b : Float) -> (Float, Float) {
  let s = a + b
  if !is_finite(s) {
    (s, Float::reinterpret_from_uint(0x7fc00000U))
  } else {
    let bb = s - a
    (s, a - (s - bb) + (b - bb))
  }
}

///|
/// Error-free sum for `|a| >= |b|` (or `a == 0`), Dekker's Fast2Sum: the same result as
/// `two_sum` with a few operations (a zero error is `+0`, as in `two_sum`; adding `0.0` to normalize it does not work because the compiler folds `x + 0.0` to `x`, which is wrong for `-0`). The result is unspecified
/// when the precondition does not hold.
pub fn fast_two_sum(a : Float, b : Float) -> (Float, Float) {
  let s = a + b
  if !is_finite(s) {
    (s, Float::reinterpret_from_uint(0x7fc00000U))
  } else {
    (s, if b - (s - a) == 0.0F { 0.0F } else { b - (s - a) })
  }
}

///|
/// Error-free product: returns `(p, e)` with `p = a * b` rounded to nearest even and
/// `e = fma(a, b, -p)`, the product error rounded once. `a * b == p + e` exactly when the
/// error is representable, which holds when the exponents of `a` and `b` add up to at least
/// `-126 + 23`; below that the error may be rounded. If `p` is not finite `e` is the quiet NaN.
pub fn two_prod(a : Float, b : Float) -> (Float, Float) {
  let p = a * b
  if !is_finite(p) {
    (p, Float::reinterpret_from_uint(0x7fc00000U))
  } else {
    (p, fma(a, b, -p))
  }
}
