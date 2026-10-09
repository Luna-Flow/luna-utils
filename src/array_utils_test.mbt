///|
test "sum" {
  let arr = [1, 2, 3, 4]
  assert_eq(@luna-utils.arr_sum(arr), 10)
  assert_eq(@luna-utils.arr_sum([]), 0)
  let arr_double = [1.0, 2.0, 3.0, 4.0]
  assert_eq(@luna-utils.arr_sum(arr_double), 10.0)
  assert_eq(@luna-utils.arr_sum([]), 0.0)
}

///|
test "zero_arr" {
  let arr : Array[Int] = @luna-utils.zero_arr(5)
  assert_eq(arr, [0, 0, 0, 0, 0])
  let arr : Array[Double] = @luna-utils.zero_arr(5)
  assert_eq(arr, [0.0, 0.0, 0.0, 0.0, 0.0])
}

///|
test "reverse" {
  let arr = [1, 2, 3, 4]
  assert_eq(@luna-utils.reverse(arr), [4, 3, 2, 1])
  assert_eq(@luna-utils.reverse([1]), [1])
}

///|
test "reverse_inplace" {
  let mut arr = [1, 2, 3, 4]
  @luna-utils.reverse_inplace(arr)
  assert_eq(arr, [4, 3, 2, 1])
  arr = [1]
  @luna-utils.reverse_inplace(arr)
  assert_eq(arr, [1])
}

///|
test "find" {
  let arr = [1, 2, 3, 4]
  assert_eq(@luna-utils.find(arr, 3), Some(2))
  assert_eq(@luna-utils.find(arr, 5), None)
}

///|
test "same_to" {
  let arr_not_same = [1, 2, 3, 4]
  let arr_same_one = [1, 1, 1, 1]
  let arr_same_two = [2, 2, 2, 2]
  assert_eq(@luna-utils.same(arr_not_same), false)
  assert_eq(@luna-utils.same(arr_same_one), true)
  assert_eq(@luna-utils.same(arr_same_two), true)
  assert_eq(@luna-utils.same_to(arr_not_same, 1), false)
  assert_eq(@luna-utils.same_to(arr_same_one, 1), true)
  assert_eq(@luna-utils.same_to(arr_same_two, 2), true)
  assert_eq(@luna-utils.map_same(arr_not_same, fn(x) { x - x }), true)
  assert_eq(@luna-utils.map_same_to(arr_same_one, 2, fn(x) { x * 2 }), true)
}
