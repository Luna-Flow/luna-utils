///|
test "clamp" {
  assert_true(@luna-utils.clamp(3, 5, 7) == 5)
  assert_true(@luna-utils.clamp(2.5, 1.5, 3.5) == 2.5)
  assert_true(@luna-utils.clamp("abc", "def", "ghi") == "def")
  assert_true(@luna-utils.clamp("xxx", "def", "ghi") == "ghi")
}

///|
test "is_between" {
  assert_true(@luna-utils.is_between(5, 5, 7))
  assert_true(@luna-utils.is_between(7, 5, 7))
  assert_false(@luna-utils.is_between(3, 5, 7))
}
