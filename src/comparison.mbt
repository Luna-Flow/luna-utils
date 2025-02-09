///|
/// Constrains a value of any comparable type within a specified range \[minimum,
/// maximum].
///
/// Parameters:
///
/// * `value` : The value to be clamped.
/// * `minimum` : The lower bound of the range (inclusive).
/// * `maximum` : The upper bound of the range (inclusive).
///
/// Returns the clamped value:
///
/// * If `value` is less than `minimum`, returns `minimum`.
/// * If `value` is greater than `maximum`, returns `maximum`.
/// * Otherwise, returns `value` unchanged.
///
/// Example:
///
/// ```moonbit
/// test "clamp" {
///   inspect!(clamp(5, 0, 10), content="5")
///   inspect!(clamp(-1, 0, 10), content="0")
///   inspect!(clamp(15, 0, 10), content="10")
/// }
/// ```
pub fn clamp[T : Compare](value : T, min : T, max : T) -> T {
  if value < min {
    min
  } else if value > max {
    max
  } else {
    value
  }
}

///|
/// Checks if a value is within a closed interval \[minimum, maximum].
///
/// Parameters:
///
/// * `value` : The value to check.
/// * `minimum` : The lower bound of the interval (inclusive).
/// * `maximum` : The upper bound of the interval (inclusive).
///
/// Returns `true` if the value is greater than or equal to `minimum` and less
/// than or equal to `maximum`, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// test "is_between" {
///   inspect!(is_between(5, 0, 10), content="true")
///   inspect!(is_between(0, 1, 10), content="false")
///   inspect!(is_between(1.5, 1.0, 2.0), content="true")
/// }
/// ```
pub fn is_between[T : Compare](value : T, min : T, max : T) -> Bool {
  value >= min && value <= max
}
