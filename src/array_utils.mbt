///|
/// Calculates the sum of all elements in an array using the monoid addition
/// operation.
///
/// Parameters:
///
/// * `array` : An array of type `A` where `A` implements the `MonoidAdd` trait.
/// The array can be empty.
///
/// Returns the sum of all elements in the array. If the array is empty, returns
/// the zero element of the monoid.
///
/// Example:
///
/// ```moonbit
/// test "arr_sum" {
///   let nums = [1, 2, 3, 4]
///   let bools = [true, false, true]
///   inspect!(arr_sum(nums), content="10")
///   inspect!(arr_sum(bools), content="true")
/// }
/// ```
pub fn arr_sum[A : MonoidAdd](arr : Array[A]) -> A {
  let mut sum = A::zero()
  for x in arr {
    sum = A::op_add(sum, x)
  }
  sum
}

///|
/// Calculates the sum of the absolute values of all elements in an array using
/// the monoid addition operation.
///
/// Parameters:
///
/// * `array` : An array of type `A` where `A` implements both the `AbelianGroup`
/// and `Compare` traits. The array can be empty.
///
/// Returns the sum of the absolute values of all elements in the array. If the
/// array is empty, returns the zero element of the monoid.
///
/// Example:
///
/// ```moonbit
/// test "arr_abs_sum" {
///   let nums = [-1, 2, -3, 4]
///   inspect!(arr_abs_sum(nums), content="10")
/// }
/// ```
pub fn arr_abs_sum[A : AbelianGroup + Compare](arr : Array[A]) -> A {
  let mut sum = A::zero()
  for x in arr {
    sum = A::op_add(sum, abs(x))
  }
  sum
}

///|
/// Creates a new array of specified length filled with the zero element of a
/// monoid.
///
/// Parameters:
///
/// * `length` : The desired length of the array. Must be non-negative.
/// * `A` : A type parameter that implements the `MonoidAdd` trait, which
/// provides the zero element.
///
/// Returns a new array of type `Array[A]` with `length` elements, where each
/// element is the zero element of type `A`.
///
/// Example:
///
/// ```moonbit
/// test "zero_arr" {
///   let int_zeros = zero_arr[Int](3)
///   let bool_zeros = zero_arr[Bool](2)
///   inspect!(int_zeros, content="[0, 0, 0]")
///   inspect!(bool_zeros, content="[false, false]")
/// }
/// ```
pub fn zero_arr[A : MonoidAdd](n : Int) -> Array[A] {
  let arr = []
  for i = 0; i < n; i = i + 1 {
    arr.push(A::zero())
  }
  arr
}

///|
/// Reverses the order of elements in an array.
///
/// Parameters:
/// * `array` : An array of any type.
///
/// Returns a new array with elements in reverse order.
///
/// Example:
/// ```moonbit
/// test "reverse" {
///   let arr = [1, 2, 3, 4]
///   inspect!(reverse(arr), content="[4, 3, 2, 1]")
///   inspect!(reverse([]), content="[]")
/// }
/// ```
pub fn reverse[T](array : Array[T]) -> Array[T] {
  let result = []
  for i = array.length() - 1; i >= 0; i = i - 1 {
    result.push(array[i])
  }
  result
}

///|
/// Reverses the order of elements in an array in-place.
///
/// Parameters:
/// * `array` : A mutable array of any type.
///
/// This function modifies the original array and does not return a new array.
///
/// Example:
/// ```moonbit
/// test "reverse_inplace" {
///   let arr = [1, 2, 3, 4]
///   reverse_inplace(arr)
///   inspect!(arr, content="[4, 3, 2, 1]")
///   let empty = []
///   reverse_inplace(empty)
///   inspect!(empty, content="[]")
/// }
/// ```
pub fn reverse_inplace[T](arr : Array[T]) -> Unit {
  let mut left = 0
  let mut right = arr.length() - 1
  while left < right {
    arr.swap(left, right)
    left = left + 1
    right = right - 1
  }
}

///|
/// Finds the index of the first occurrence of a value in an array.
///
/// Parameters:
/// * `array` : An array of any type.
/// * `value` : The value to search for.
///
/// Returns the index of the value if found, otherwise -1.
///
/// Example:
/// ```moonbit
/// test "find" {
///   let arr = [1, 2, 3, 4]
///   inspect!(find(arr, 3), content="2")
///   inspect!(find(arr, 5), content="-1")
/// }
/// ```
pub fn find[T : Eq](array : Array[T], value : T) -> Int? {
  for i = 0; i < array.length(); i = i + 1 {
    if array[i] == value {
      return Some(i)
    }
  }
  None
}
