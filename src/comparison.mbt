///|
/// Constrains a value to lie within a specified range by returning the closest
/// value within the bounds.
///
/// Parameters:
///
/// * `value` : The value to be clamped.
/// * `min` : The minimum bound of the range.
/// * `max` : The maximum bound of the range.
///
/// Returns the clamped value: `min` if `value` is less than `min`, `max` if
/// `value` is greater than `max`, otherwise `value` itself.
///
/// Example:
///
/// ```moonbit nocheck
/// inspect(clamp(5, 1, 10), content="5")
/// inspect(clamp(-3, 1, 10), content="1")
/// inspect(clamp(15, 1, 10), content="10")
/// ```
///
pub fn[T : Compare] clamp(value : T, min : T, max : T) -> T {
  if value < min {
    min
  } else if value > max {
    max
  } else {
    value
  }
}

///|
/// Checks if a value falls within the inclusive range defined by minimum and
/// maximum bounds.
///
/// Parameters:
///
/// * `value` : The value to check.
/// * `min` : The minimum bound of the range (inclusive).
/// * `max` : The maximum bound of the range (inclusive).
///
/// Returns `true` if the value is within the range \[min, max], `false`
/// otherwise.
///
/// Example:
///
/// ```moonbit nocheck
/// inspect(is_between(5, 1, 10), content="true")
/// inspect(is_between(0, 1, 10), content="false")
/// inspect(is_between(10, 1, 10), content="true")
/// ```
///
pub fn[T : Compare] is_between(value : T, min : T, max : T) -> Bool {
  value >= min && value <= max
}
