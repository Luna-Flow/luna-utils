# array_utils API

`array_utils` is the part of the package `Luna-Flow/luna-utils` defined in [`src/array_utils.mbt`](../../../src/array_utils.mbt): twelve functions on `Array[T]`. They are package-level functions, not methods, so another package calls them as `@luna-utils.arr_sum(xs)`. The traits `AddMonoid` and `Num` come from [luna-generic](https://luna-flow.github.io/en/luna-generic/).

## Sums

```mbti
fn[A : @luna-generic.AddMonoid] arr_sum(Array[A]) -> A
fn[A : @luna-generic.Num + Compare] arr_abs_sum(Array[A]) -> A
fn[A : @luna-generic.AddMonoid] zero_arr(Int) -> Array[A]
```

`arr_sum(arr)` adds the elements from left to right, starting from `zero()`. The sum of an empty array is `zero()`.

`arr_abs_sum(arr)` adds the absolute values of the elements in the same way. The absolute value of `x` is `-x` when `x < zero()` and `x` otherwise.

`zero_arr(n)` returns a new array of length `n` whose elements are all `zero()`. The element type is chosen by the expected type, for example `let zeros : Array[Double] = zero_arr(3)`.

## Extremes

```mbti
fn[T : Compare] arr_max(Array[T]) -> T
fn[T : Compare] arr_min(Array[T]) -> T
```

`arr_max(arr)` and `arr_min(arr)` return the largest and the smallest element; when several elements compare equal, the first of them is returned. Both panic on an empty array.

## Order and search

```mbti
fn[T] reverse(Array[T]) -> Array[T]
fn[T] reverse_inplace(Array[T]) -> Unit
fn[T : Eq] find(Array[T], T) -> Int?
```

`reverse(arr)` returns a new array with the elements in reverse order and leaves `arr` unchanged. `reverse_inplace(arr)` reverses `arr` itself by swapping elements from both ends toward the middle; an empty array is left as it is.

`find(arr, value)` returns `Some(i)` for the first index `i` with `arr[i] == value`, or `None` when no element equals `value`.

## Uniformity

```mbti
fn[T : Eq] same(Array[T]) -> Bool
fn[T : Eq] same_to(Array[T], T) -> Bool
fn[U, V : Eq] map_same(Array[U], (U) -> V) -> Bool
fn[U, V : Eq] map_same_to(Array[U], V, (U) -> V) -> Bool
```

| Function | Returns `true` when | On an empty array |
| --- | --- | --- |
| `same(arr)` | every element equals `arr[0]` | panics |
| `same_to(arr, sample)` | every element equals `sample` | returns `true` |
| `map_same(arr, f)` | every `f(x)` equals `f(arr[0])` | panics |
| `map_same_to(arr, sample, f)` | every `f(x)` equals `sample` | returns `true` |

The checks stop at the first element that differs. `map_same` and `map_same_to` build the mapped array first, so `f` is called once for every element.
