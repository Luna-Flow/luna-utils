# comparison design

`comparison` holds the range helpers `clamp` and `is_between` in [`src/comparison.mbt`](../../../src/comparison.mbt). This page records the conventions they share and the behaviour that maintainers must keep stable.

## Conventions

- Both functions take the value first and the bounds after it, in the order `min`, `max`.
- Ranges are closed: a value equal to a bound is inside the range.
- The only constraint is `Compare`, so the functions do not depend on luna-generic and apply to any ordered type, including `String`.
- The bounds are not validated. Neither function aborts when `min > max`; the [API reference](../api/comparison.md) states what they return in that case.

## Consistency

For `min <= max`, `is_between(v, min, max)` is `true` exactly when `clamp(v, min, max)` returns `v`. Changes to one function must keep this relation.

## Maintenance notes

- Update this page and the [API reference](../api/comparison.md) whenever a function is added or removed, or its constraints or edge-case behaviour change, and regenerate `src/pkg.generated.mbti` with `moon info`.
- Validating the bounds would change the behaviour described above; document it here if it is ever introduced.
