# array_utils tutorial

This tutorial walks through the array helpers with small examples taken from the doc comments and tests in `src`. To use them in your own module, add the dependency with `moon add Luna-Flow/luna-utils` and import the package `Luna-Flow/luna-utils`; the functions are then available as `@luna-utils.arr_sum` and so on. The examples below run inside the package and omit the prefix.

## Sums

`arr_sum` works for any element type with an additive monoid, and `zero_arr` creates an array of zeros of the expected type:

```moonbit
inspect(arr_sum([1, 2, 3, 4]), content="10")
let empty : Array[Int] = []
inspect(arr_sum(empty), content="0")
inspect(arr_abs_sum([1, -2, 3, -4, 5]), content="15")
let zeros : Array[Double] = zero_arr(3)
assert_eq(zeros, [0.0, 0.0, 0.0])
```

## Extremes and search

```moonbit
let xs = [5, 2, 8, 1, 9]
inspect(arr_max(xs), content="9")
inspect(arr_min(xs), content="1")
inspect(find([1, 2, 3, 2, 4], 2), content="Some(1)")
inspect(find([1, 2, 3, 2, 4], 5), content="None")
```

`arr_max` and `arr_min` panic on an empty array, so check `xs.is_empty()` first when the array may be empty.

## Reversing

`reverse` returns a new array, while `reverse_inplace` changes its argument:

```moonbit
let original = [1, 2, 3, 4, 5]
inspect(reverse(original), content="[5, 4, 3, 2, 1]")
inspect(original, content="[1, 2, 3, 4, 5]")
reverse_inplace(original)
inspect(original, content="[5, 4, 3, 2, 1]")
```

## Checking uniformity

`same` and `same_to` compare the elements themselves; `map_same` and `map_same_to` compare their images under a function:

```moonbit
inspect(same([1, 1, 1, 1]), content="true")
inspect(same_to([1, 2, 1, 1], 1), content="false")
inspect(map_same([2, 4, 6, 8], x => x % 2), content="true")
inspect(map_same_to([1, 1, 1], 2, x => x * 2), content="true")
```

`same` and `map_same` panic on an empty array. When the array may be empty and you know the expected value, use `same_to` or `map_same_to`, which return `true` for an empty array.

## Next steps

The [API reference](../api/array_utils.md) gives every signature, and the [design notes](../design/array_utils.md) explain the constraints and the treatment of empty arrays. Before relying on edge-case behaviour, check it against the tests in `src/array_utils_test.mbt`.
