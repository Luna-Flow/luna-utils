///|
/// The four mutually exclusive relations of IEEE 754-2019 §5.11. `Unordered`
/// arises when at least one operand is a NaN.
pub(all) enum Relation {
  Less
  Equal
  Greater
  Unordered
} derive(Eq, Debug)

///|
pub extend Relation with Eq::{equal, not_equal}

///|
pub extend Relation with @debug.Debug::{to_repr}

///|
/// The 22 comparison predicates of IEEE 754-2019 §5.6.1 (Tables 5.1 and 5.2).
/// Each is true exactly for the relations it names; the `Signaling` forms also
/// signal invalid operation for quiet NaN operands.
pub(all) enum ComparisonPredicate {
  QuietEqual
  QuietNotEqual
  SignalingEqual
  SignalingNotEqual
  SignalingGreater
  SignalingNotGreater
  SignalingGreaterEqual
  SignalingLessUnordered
  SignalingLess
  SignalingNotLess
  SignalingLessEqual
  SignalingGreaterUnordered
  QuietGreater
  QuietNotGreater
  QuietGreaterEqual
  QuietLessUnordered
  QuietLess
  QuietNotLess
  QuietLessEqual
  QuietGreaterUnordered
  QuietUnordered
  QuietOrdered
} derive(Eq, Debug)

///|
pub extend ComparisonPredicate with Eq::{equal, not_equal}

///|
pub extend ComparisonPredicate with @debug.Debug::{to_repr}

///|
fn relation_mask(r : Relation) -> Int32 {
  match r {
    Less => 1
    Equal => 2
    Greater => 4
    Unordered => 8
  }
}

///|
/// Bit mask (Less 1, Equal 2, Greater 4, Unordered 8) of the relations for
/// which the predicate is true.
fn predicate_relations(p : ComparisonPredicate) -> Int32 {
  match p {
    QuietEqual => 2
    QuietNotEqual => 13
    SignalingEqual => 2
    SignalingNotEqual => 13
    SignalingGreater => 4
    SignalingNotGreater => 11
    SignalingGreaterEqual => 6
    SignalingLessUnordered => 9
    SignalingLess => 1
    SignalingNotLess => 14
    SignalingLessEqual => 3
    SignalingGreaterUnordered => 12
    QuietGreater => 4
    QuietNotGreater => 11
    QuietGreaterEqual => 6
    QuietLessUnordered => 9
    QuietLess => 1
    QuietNotLess => 14
    QuietLessEqual => 3
    QuietGreaterUnordered => 12
    QuietUnordered => 8
    QuietOrdered => 7
  }
}

///|
/// True for the predicates named `Signaling`.
fn predicate_is_signaling(p : ComparisonPredicate) -> Bool {
  match p {
    QuietEqual => false
    QuietNotEqual => false
    SignalingEqual => true
    SignalingNotEqual => true
    SignalingGreater => true
    SignalingNotGreater => true
    SignalingGreaterEqual => true
    SignalingLessUnordered => true
    SignalingLess => true
    SignalingNotLess => true
    SignalingLessEqual => true
    SignalingGreaterUnordered => true
    QuietGreater => false
    QuietNotGreater => false
    QuietGreaterEqual => false
    QuietLessUnordered => false
    QuietLess => false
    QuietNotLess => false
    QuietLessEqual => false
    QuietGreaterUnordered => false
    QuietUnordered => false
    QuietOrdered => false
  }
}

///|
/// IEEE 754-2019 §5.11 relation of two binary64 encodings: every NaN is
/// unordered with everything, `+0 = -0`, and infinities of the same sign are
/// equal.
pub fn relation_bits(x : UInt64, y : UInt64) -> Relation {
  if is_nan_bits(x) || is_nan_bits(y) {
    Unordered
  } else if is_zero_bits(x) && is_zero_bits(y) {
    Equal
  } else {
    let kx = total_order_key_bits(x)
    let ky = total_order_key_bits(y)
    if kx < ky {
      Less
    } else if kx > ky {
      Greater
    } else {
      Equal
    }
  }
}

///|
/// Relation of two portable binary64 values; any NaN is unordered.
pub fn relation(x : Double, y : Double) -> Relation {
  relation_bits(to_bits_canonical(x), to_bits_canonical(y))
}

///|
/// Shared evaluation step of the comparison predicates for every format:
/// the predicate is true exactly for the relations it names, and `invalid` is
/// true for a signaling NaN operand with any predicate and for a NaN operand
/// with a `Signaling` predicate (IEEE 754-2019 §5.11). Returns `(value, invalid)`.
pub fn predicate_outcome(
  predicate : ComparisonPredicate,
  relation : Relation,
  signaling_nan_operand : Bool,
  nan_operand : Bool,
) -> (Bool, Bool) {
  let value = (predicate_relations(predicate) & relation_mask(relation)) != 0
  (
    value,
    signaling_nan_operand || (predicate_is_signaling(predicate) && nan_operand),
  )
}

///|
/// Evaluate a comparison predicate on raw binary64 encodings. The result is
/// `(value, invalid)` as in `predicate_outcome`. Raw encodings preserve the
/// signaling state of NaNs.
pub fn compare_predicate_bits(
  predicate : ComparisonPredicate,
  x : UInt64,
  y : UInt64,
) -> (Bool, Bool) {
  predicate_outcome(
    predicate,
    relation_bits(x, y),
    is_signaling_bits(x) || is_signaling_bits(y),
    is_nan_bits(x) || is_nan_bits(y),
  )
}

///|
/// Evaluate a comparison predicate on portable binary64 values. The signaling
/// state of a numeric NaN is not observable, so only the `Signaling` predicates
/// report `invalid`, for every NaN operand.
pub fn compare_predicate(
  predicate : ComparisonPredicate,
  x : Double,
  y : Double,
) -> (Bool, Bool) {
  compare_predicate_bits(predicate, to_bits_canonical(x), to_bits_canonical(y))
}
