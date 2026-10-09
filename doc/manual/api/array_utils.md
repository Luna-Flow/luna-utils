# Array API migration

All names below were exported by 0.1.x and are absent in 0.2.0. These core operations are migration candidates, not new luna-utils exports or a promise of identical numeric semantics.

| Removed API | Core migration |
| --- | --- |
| `arr_sum` | `xs.fold(init=zero, (a, b) => a + b)` |
| `zero_arr` | `Array::make(n, zero)` |
| `arr_abs_sum` | `xs.fold(init=zero, (a, b) => a + b.abs())` |
| `reverse` / `reverse_inplace` | `xs.rev()` / `xs.rev_in_place()` |
| `find` | `xs.search(value)` |
| `same` / `same_to` | `xs.all(x => x == sample)` |
| `map_same` / `map_same_to` | `xs.all(x => f(x) == sample)` |
| `arr_max` / `arr_min` | `xs.iter().maximum()` / `xs.iter().minimum()` |

Choose an explicit additive identity and supported element operations. Core does not supply the removed luna-generic trait constraints. For absolute sums, `Int::abs(-2147483648)` returns the negative minimum because its positive magnitude is not representable; addition can overflow. Floating-point sums round at each addition, and NaN propagates through ordinary arithmetic.

The legacy extrema and `same`/`map_same` panicked on empty arrays. Core iterator extrema return `None`; `all` returns `true`. For `same`, choose the first element only after handling the empty case. Mapping followed by `all` preserves eager mapping; putting `f` inside `all` short-circuits and may change effects or exceptions.

Core extrema use `Compare`; they are not the planned IEEE 754 minimum/maximum of #23. Review NaN, signed zero and equal-element selection separately. `Double::abs` also clears the sign of negative zero, whereas the legacy comparison-based absolute value retained it.
