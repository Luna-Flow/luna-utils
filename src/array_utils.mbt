///|
/// Computes the sum of all elements in an array using the additive monoid
/// operation.
///
/// Parameters:
///
/// * `arr` : The array of elements to sum.
///
/// Returns the sum of all elements in the array, or the zero element of the
/// monoid if the array is empty.
///
/// Example:
///
/// ```moonbit
/// let numbers = [1, 2, 3, 4, 5]
/// inspect(arr_sum(numbers), content="15")
///
/// let empty_array : Array[Int] = []
/// inspect(arr_sum(empty_array), content="0")
/// ```
///
pub fn[A : AddMonoid] arr_sum(arr : Array[A]) -> A {
  arr.fold(A::op_add, init=A::zero())
}

///|
/// Calculates the sum of absolute values of all elements in the array.
///
/// Parameters:
///
/// * `arr` : The array containing numeric elements to process.

///|
/// Creates an array of length `n` filled with zero values of type `A`.
///
/// Parameters:
///
/// * `n` : The length of the array to create.
///
/// Returns an array of length `n` where each element is the zero value of type
/// `A`.
///
/// Example:
///
/// ```moonbit
/// let zeros:Array[Int] = zero_arr(5) // Creates [0, 0, 0, 0, 0] for Int
/// inspect(zeros.length(), content="5")
/// inspect(zeros[0], content="0")
/// ```
///
pub fn[A : AddMonoid] zero_arr(n : Int) -> Array[A] {
  Array::make(n, A::zero())
} // Example:

///|
/// ```moonbit
/// let numbers = [1, -2, 3, -4, 5]
/// inspect(arr_abs_sum(numbers), content="15")
/// ```
///
pub fn[A : Num + Compare] arr_abs_sum(arr : Array[A]) -> A {
  let abs = x => if x < A::zero() { -x } else { x }
  arr.fold(fn(acc, x) { A::op_add(acc, abs(x)) }, init=A::zero())
}

///|
/// Creates a new array with elements in reverse order of the input array.
///
/// Parameters:
///
/// * `array` : The array to reverse.
///
/// Returns a new array containing the same elements as the input array, but in
/// reverse order.
///
/// Example:
///
/// ```moonbit
/// let original = [1, 2, 3, 4, 5]
/// let reversed = reverse(original)
/// inspect(reversed, content="[5, 4, 3, 2, 1]")
/// ```
///
pub fn[T] reverse(array : Array[T]) -> Array[T] {
  array.rev_iter().collect()
}

///|
/// Reverses the elements of an array in place by swapping elements from both
/// ends toward the center.
///
/// Parameters:
///
/// * `arr` : The array to be reversed in place.
///
/// Panics if the array is empty when accessing `arr[0]` to determine the
/// array's length.
///
/// Example:
///
/// ```moonbit
/// let numbers = [1, 2, 3, 4, 5]
/// reverse_inplace(numbers)
/// inspect(numbers, content="[5, 4, 3, 2, 1]")
/// ```
///
pub fn[T] reverse_inplace(arr : Array[T]) -> Unit {
  for i = 0; i < arr.length() / 2; i = i + 1 {
    arr.swap(i, arr.length() - i - 1)
  }
}

///|
/// Searches for the first occurrence of a value in an array and returns its
/// index.
///
/// Parameters:
///
/// * `array` : The array to search in.
/// * `value` : The value to search for.
///
/// Returns `Some(index)` if the value is found, where `index` is the position
/// of the first occurrence, or `None` if the value is not found in the array.
///
/// Example:
///
/// ```moonbit
/// let arr = [1, 2, 3, 2, 4]
/// inspect(find(arr, 2), content="Some(1)")
/// inspect(find(arr, 5), content="None")
/// ```
///
pub fn[T : Eq] find(array : Array[T], value : T) -> Int? {
  array.search_by(fn(x) { x == value })
}

///|
/// Checks if all elements in an array are equal to each other.
///
/// Parameters:
///
/// * `array` : The array to check for uniformity.
///
/// Returns `true` if all elements in the array are equal to the first element,
/// `false` otherwise.
///
/// Panics if the array is empty (when accessing `array[0]`).
///
/// Example:
///
/// ```moonbit
/// let uniform = [1, 1, 1, 1]
/// let mixed = [1, 2, 1, 1]
/// inspect(same(uniform), content="true")
/// inspect(same(mixed), content="false")
/// ```
///
pub fn[T : Eq] same(array : Array[T]) -> Bool {
  let sample = array[0]
  for a in array {
    if a != sample {
      return false
    }
  }
  true
}

///|
/// Checks if all elements in the array map to the same value when transformed
/// by the given function.
///
/// Parameters:
///
/// * `array` : The array to check.
/// * `f` : The transformation function to apply to each element.
///
/// Returns `true` if all elements map to the same value, `false` otherwise.
///

///|
/// Checks if all elements in an array are equal to a specific value.
///
/// Parameters:
///
/// * `array` : The array to check.
/// * `sample` : The value to compare all elements against.
///
/// Returns `true` if all elements in the array are equal to the sample value,
/// `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// let arr1 = [1, 1, 1, 1]
/// let arr2 = [1, 2, 1, 1]
/// inspect(same_to(arr1, 1), content="true")
/// inspect(same_to(arr2, 1), content="false")
/// ```
///
pub fn[T : Eq] same_to(array : Array[T], sample : T) -> Bool {
  for a in array {
    if a != sample {
      return false
    }
  }
  true
} // inspect(map_same(numbers, fn(x) { x % 2 }), content="false")

///|
/// let same_parity = [2, 4, 6, 8]
/// inspect(map_same(same_parity, fn(x) { x % 2 }), content="true")
/// ```
///
pub fn[U, V : Eq] map_same(array : Array[U], f : (U) -> V) -> Bool {
  let mapped = array.map(f)
  same(mapped)
}

///|
/// Checks if all elements in an array, when mapped by a function, are equal to
/// a given sample value.
///
/// Parameters:
///
/// * `array` : The input array of elements to be transformed and checked.
/// * `sample` : The expected value that all mapped elements should equal.
/// * `f` : The transformation function to apply to each element in the array.
///
/// Returns `true` if all elements in the array, when transformed by the
/// function, equal the sample value; `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// let numbers = [1, 2, 3, 4]
/// let double = fn(x) { x * 2 }
/// inspect(map_same_to(numbers, 6, double), content="false")
///
/// let ones = [1, 1, 1]
/// inspect(map_same_to(ones, 2, double), content="true")
/// ```
///
pub fn[U, V : Eq] map_same_to(
  array : Array[U],
  sample : V,
  f : (U) -> V,
) -> Bool {
  let mapped = array.map(f)
  same_to(mapped, sample)
}

///|
/// Finds the maximum element in an array.
///
/// Parameters:
///
/// * `array` : `Array[T]` - The array to search for the maximum element.
///
/// Returns the maximum element of type `T` found in the array.
///
/// Panics if the array is empty (when accessing `array[0]`).
///
/// Example:
///
/// ```moonbit
/// let numbers = [1, 5, 3, 9, 2]
/// let max_num = arr_max(numbers)
/// inspect(max_num, content="9")
/// ```
///
pub fn[T : Compare] arr_max(array : Array[T]) -> T {
  let mut max = array[0]
  for a in array {
    if a > max {
      max = a
    }
  }
  max
}

///|
/// Finds the minimum element in an array by comparing all elements.
///
/// Parameters:
///
/// * `array` : The array to find the minimum element from.
///
/// Returns the minimum element found in the array.
///
/// Panics if the array is empty (when accessing `array[0]`).
///
/// Example:
///
/// ```moonbit
/// let numbers = [5, 2, 8, 1, 9]
/// inspect(arr_min(numbers), content="1")
/// ```
///
pub fn[T : Compare] arr_min(array : Array[T]) -> T {
  let mut min = array[0]
  for a in array {
    if a < min {
      min = a
    }
  }
  min
}
