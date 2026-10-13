///|
/// IEEE 754-2019 §5.11 relation of two binary32 encodings: every NaN is
/// unordered with everything, `+0 = -0`, and infinities of the same sign are
/// equal.
pub fn relation_bits(x : UInt32, y : UInt32) -> @binary64.Relation {
  if is_nan_bits(x) || is_nan_bits(y) {
    @binary64.Unordered
  } else if is_zero_bits(x) && is_zero_bits(y) {
    @binary64.Equal
  } else {
    let kx = total_order_key_bits(x)
    let ky = total_order_key_bits(y)
    if kx < ky {
      @binary64.Less
    } else if kx > ky {
      @binary64.Greater
    } else {
      @binary64.Equal
    }
  }
}

///|
/// Relation of two portable binary32 values; any NaN is unordered.
pub fn relation(x : Float, y : Float) -> @binary64.Relation {
  relation_bits(to_bits_canonical(x), to_bits_canonical(y))
}

///|
/// Evaluate a comparison predicate on raw binary32 encodings; see
/// `@float.predicate_outcome` for the meaning of `(value, invalid)`.
pub fn compare_predicate_bits(
  predicate : @binary64.ComparisonPredicate,
  x : UInt32,
  y : UInt32,
) -> (Bool, Bool) {
  @binary64.predicate_outcome(
    predicate,
    relation_bits(x, y),
    is_signaling_bits(x) || is_signaling_bits(y),
    is_nan_bits(x) || is_nan_bits(y),
  )
}

///|
/// Evaluate a comparison predicate on portable binary32 values; see
/// `@float.compare_predicate`.
pub fn compare_predicate(
  predicate : @binary64.ComparisonPredicate,
  x : Float,
  y : Float,
) -> (Bool, Bool) {
  compare_predicate_bits(predicate, to_bits_canonical(x), to_bits_canonical(y))
}
