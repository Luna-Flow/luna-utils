///|
/// Calculates the sum of all elements in an array using the monoid addition
/// operation.
///
/// Parameters:
///
/// * `array` : An array of type `A` where `A` implements the `AddMonoid` trait.
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
pub fn arr_sum[A : AddMonoid](arr : Array[A]) -> A {
  arr.fold(A::op_add, init=A::zero())
}

///|
/// Calculates the sum of the absolute values of all elements in an array using
/// the monoid addition operation.
///
/// Parameters:
///
/// * `array` : An array of type `A` where `A` implements both the `Num`
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
pub fn arr_abs_sum[A : Num + Compare](arr : Array[A]) -> A {
  let abs = fn { x => if x < A::zero() { -x } else { x } }
  arr.fold(fn(acc, x) { A::op_add(acc, abs(x)) }, init=A::zero())
}

///|
/// Creates a new array of specified length filled with the zero element of a
/// monoid.
///
/// Parameters:
///
/// * `length` : The desired length of the array. Must be non-negative.
/// * `A` : A type parameter that implements the `AddMonoid` trait, which
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
pub fn zero_arr[A : AddMonoid](n : Int) -> Array[A] {
  Array::make(n, A::zero())
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
  array.rev_iter().collect()
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
  for i = 0; i < arr.length() / 2; i = i + 1 {
    arr.swap(i, arr.length() - i - 1)
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
  array.search_by(fn(x) { x == value })
}

///|
/// Checks if all elements in an array are equal.
///
/// Parameters:
///
/// * `array` : An array of type `T` where `T` implements the `Eq` trait. Must be
/// non-empty.
///
/// Returns `true` if all elements in the array are equal to each other, `false`
/// otherwise.
///
/// Example:
///
/// ```moonbit
/// ///|
/// test "same" {
/// inspect!(same([1, 1, 1]), content="true")
/// inspect!(same([1, 2, 1]), content="false")
/// }
/// ```
pub fn same[T : Eq](array : Array[T]) -> Bool {
  let sample = array[0]
  for a in array {
    if a != sample {
      return false
    }
  }
  true
}

///|
/// Checks if applying a function to all elements in an array produces equal
/// results.
///
/// Parameters:
///
/// * `array` : An array of elements of type `U`.
/// * `f` : A function that takes a value of type `U` and returns a value of type
/// `V`, where `V` implements the `Eq` trait.
///
/// Returns `true` if all elements in the array, after applying function `f`, are
/// equal to each other, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// ///|
/// test "map_same" {
/// let arr = ["a", "ab", "abc"]
/// inspect!(map_same(arr, fn(s) { s.length() }), content="false")
/// let arr2 = ["aa", "bb", "cc"]
/// inspect!(map_same(arr2, fn(s) { s.length() }), content="true")
/// }
/// ```
pub fn map_same[U, V : Eq](array : Array[U], f : (U) -> V) -> Bool {
  let mapped = array.map(f)
  same(mapped)
}

///|
/// Checks if all elements in an array are equal to a given sample value.
///
/// Parameters:
///
/// * `array` : An array of type `T` where `T` implements the `Eq` trait.
/// * `sample` : A value of type `T` to compare against each element in the
/// array.
///
/// Returns `true` if all elements in the array are equal to the sample value,
/// `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// ///|
/// test "same_to" {
///   let arr = [1, 1, 1]
///   inspect!(same_to(arr, 1), content="true")
///   inspect!(same_to(arr, 2), content="false")
/// }
/// ```
pub fn same_to[T : Eq](array : Array[T], sample : T) -> Bool {
  for a in array {
    if a != sample {
      return false
    }
  }
  true
}

///|
/// Checks if applying a function to all elements in an array produces results
/// equal to a given sample value.
///
/// Parameters:
///
/// * `array` : An array of elements of type `U`.
/// * `sample` : A value of type `V` to compare against.
/// * `f` : A function that takes a value of type `U` and returns a value of type
/// `V`, where `V` implements the `Eq` trait.
///
/// Returns `true` if all elements in the array, after applying function `f`, are
/// equal to the sample value, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// ///|
/// test "map_same_to" {
///   let nums = ["one", "two", "six"]
///   inspect!(map_same_to(nums, 3, fn(s) { s.length() }), content="true")
///   inspect!(map_same_to(nums, 4, fn(s) { s.length() }), content="false")
/// }
/// ```
pub fn map_same_to[U, V : Eq](
  array : Array[U],
  sample : V,
  f : (U) -> V
) -> Bool {
  let mapped = array.map(f)
  same_to(mapped, sample)
}

///|
/// Finds the maximum element in an array of comparable values.
///
/// Parameters:
///
/// * `array` : A non-empty array of elements that can be compared with each
/// other. The type of elements must implement the `Compare` trait.
///
/// Returns the largest element in the array.
///
/// Example:
///
/// ```moonbit
/// ///|
/// test "arr_max" {
///   let nums = [1, 4, 2, 5, 3]
///   inspect!(arr_max(nums), content="5")
/// }
/// ```
pub fn arr_max[T : Compare](array : Array[T]) -> T {
  let mut max = array[0]
  for a in array {
    if a > max {
      max = a
    }
  }
  max
}

///|
/// Finds the minimum element in an array of comparable values.
///
/// Parameters:
///
/// * `array` : A non-empty array of elements that can be compared with each
/// other. The type of elements must implement the `Compare` trait.
///
/// Returns the smallest element in the array.
///
/// Example:
///
/// ```moonbit
/// ///|
/// test "arr_min" {
///   let nums = [1, 4, 2, 5, 3]
///   inspect!(arr_min(nums), content="1")
/// }
/// ```
pub fn arr_min[T : Compare](array : Array[T]) -> T {
  let mut min = array[0]
  for a in array {
    if a < min {
      min = a
    }
  }
  min
}
