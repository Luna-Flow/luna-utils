///|
test "sum" {
  let arr = [1, 2, 3, 4]
  assert_eq!(arr_sum(arr), 10)
  assert_eq!(arr_sum([]), 0)
  let arr_double = [1.0, 2.0, 3.0, 4.0]
  assert_eq!(arr_sum(arr_double), 10.0)
  assert_eq!(arr_sum([]), 0.0)
  let arr_bool = [true, false, true]
  assert_eq!(arr_sum(arr_bool), true)
  assert_eq!(arr_sum([]), false)
}

///|
test "zero_arr" {
  let arr : Array[Int] = zero_arr(5)
  assert_eq!(arr, [0, 0, 0, 0, 0])
  let arr : Array[Double] = zero_arr(5)
  assert_eq!(arr, [0.0, 0.0, 0.0, 0.0, 0.0])
  let arr : Array[Bool] = zero_arr(5)
  assert_eq!(arr, [false, false, false, false, false])
}

///|
test "reverse" {
  let arr = [1, 2, 3, 4]
  inspect!(reverse(arr), content="[4, 3, 2, 1]")
  inspect!(reverse([1]), content="[1]")
}

///|
test "reverse_inplace" {
  let mut arr = [1, 2, 3, 4]
  reverse_inplace(arr)
  inspect!(arr, content="[4, 3, 2, 1]")
  arr = [1]
  reverse_inplace(arr)
  inspect!(arr, content="[1]")
}

///|
test "find" {
  let arr = [1, 2, 3, 4]
  inspect!(find(arr, 3), content="Some(2)")
  inspect!(find(arr, 5), content="None")
}
