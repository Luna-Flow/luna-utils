# Comparison API migration

The 0.1.x functions `clamp` and `is_between` are removed. For ordered inputs use `value.clamp(min=lo, max=hi)` where the type provides it, or import `moonbitlang/core/cmp` and use `@cmp.maximum(lo, @cmp.minimum(value, hi))`. Membership can be written as `lo <= value && value <= hi`.

Require `lo <= hi` and a consistent total order for the generic expression. Core numeric clamp aborts for reversed bounds; legacy clamp did not validate them. Floating-point NaN is unordered, so operator-based membership and Compare-based extrema need separate contracts. Do not infer IEEE 754 semantics, signed-zero selection or exception flags from this migration.
