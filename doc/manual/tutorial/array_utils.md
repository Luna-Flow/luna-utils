# Array migration tutorial

These examples use core only; do not import luna-utils for the removed helpers. The chosen Int identity is zero.

```moonbit
let xs = [1, -2, 3]
assert_eq(xs.fold(init=0, (a, b) => a + b), 2)
assert_eq(xs.fold(init=0, (a, b) => a + b.abs()), 6)
assert_eq(Array::make(3, 0), [0, 0, 0])
assert_eq(xs.search(-2), Some(1))
assert_eq(xs.iter().maximum(), Some(3))
assert_eq(xs.iter().minimum(), Some(-2))
assert_eq(xs.rev(), [3, -2, 1])
xs.rev_in_place()
assert_eq(xs, [3, -2, 1])
let empty : Array[Int] = []
assert_eq(empty.iter().maximum(), None)
assert_true(empty.all(x => x == 1))
let ys = [2, 2, 2]
let uniform = if ys.is_empty() { true } else { ys.all(x => x == ys[0]) }
assert_true(uniform)
assert_true(ys.all(x => x * 2 == 4))
```

The examples cover ordinary representable integers. Read the [migration API](../api/array_utils.md) before handling overflow, NaN, empty input or effectful mapping.
