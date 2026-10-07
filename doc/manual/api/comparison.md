# comparison API

`comparison` is the part of the package `Luna-Flow/luna-utils` defined in [`src/comparison.mbt`](../../../src/comparison.mbt): two functions that compare a value with a closed range. Both need only `Compare`, so they work for numbers, strings and any other ordered type.

```mbti
fn[T : Compare] clamp(T, T, T) -> T
fn[T : Compare] is_between(T, T, T) -> Bool
```

## `clamp`

`clamp(value, min, max)` returns `min` when `value < min`, `max` when `value > max`, and `value` otherwise.

The bounds are not checked. When `min > max`, the result is `min` for a value below `min` and `max` for every other value.

## `is_between`

`is_between(value, min, max)` returns `true` when `min <= value` and `value <= max`; both bounds belong to the range. When `min > max`, it returns `false` for every value.
