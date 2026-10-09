# Comparison migration tutorial

Use a type-provided clamp for valid ordered bounds. This example requires no luna-utils import.

```moonbit
assert_eq((5).clamp(min=1, max=10), 5)
assert_eq((-3).clamp(min=1, max=10), 1)
assert_eq((15).clamp(min=1, max=10), 10)
let value = 5
assert_true(1 <= value && value <= 10)
```

For a generic Compare-based expression, import `moonbitlang/core/cmp` as `cmp` in moon.pkg. Validate bounds yourself and consult the [comparison migration API](../api/comparison.md) for semantic differences.
