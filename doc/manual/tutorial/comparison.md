# comparison tutorial

This tutorial shows the two range helpers with examples taken from the doc comments and tests in `src`. As in the [array_utils tutorial](array_utils.md), the examples run inside the package; from another package, call the functions as `@luna-utils.clamp` and `@luna-utils.is_between`.

## Clamping a value

`clamp` moves a value into a range, and leaves it unchanged when it is already inside:

```moonbit
inspect(clamp(5, 1, 10), content="5")
inspect(clamp(-3, 1, 10), content="1")
inspect(clamp(15, 1, 10), content="10")
```

Any type with `Compare` works, for example strings in lexicographic order:

```moonbit
assert_true(clamp("abc", "def", "ghi") == "def")
assert_true(clamp("xxx", "def", "ghi") == "ghi")
```

## Testing membership

`is_between` tests whether a value lies in a range; both bounds are included:

```moonbit
inspect(is_between(5, 1, 10), content="true")
inspect(is_between(10, 1, 10), content="true")
inspect(is_between(0, 1, 10), content="false")
```

## Next steps

Neither function checks that `min <= max`; pass the bounds in that order. The [API reference](../api/comparison.md) describes the result for reversed bounds, and the [design notes](../design/comparison.md) list the conventions the two functions share.
