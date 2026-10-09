# array_utils design

`array_utils` collects small generic helpers on `Array[T]` in [`src/array_utils.mbt`](../../../src/array_utils.mbt). This page explains the choices behind them and the behaviour that maintainers must keep stable.

## Constraints from luna-generic

Each function asks for the weakest constraint it needs. `reverse` and `reverse_inplace` need none, `find` and the uniformity checks need `Eq`, and `arr_max` and `arr_min` need `Compare`. `arr_sum` and `zero_arr` need only `AddMonoid` from luna-generic, that is `zero()` and `+`, so they work for every type with an additive monoid and not only for numbers. `arr_abs_sum` needs `Num` for negation and `Compare` to find the sign.

The package imports luna-generic under the alias `lf_alg`, and [`src/alias.mbt`](../../../src/alias.mbt) uses MoonBit's `using` declaration to make `AddMonoid` and `Num` available without a prefix inside the package. Public signatures name them `@luna-generic.AddMonoid` and `@luna-generic.Num`.

## Functions instead of methods

MoonBit does not let a package define methods on `Array`, which belongs to the core library, so the helpers are package-level functions.

## Empty arrays

The functions that need an element to start from read `arr[0]` and therefore panic on an empty array: `arr_max`, `arr_min`, `same` and `map_same`. They do not return an `Option`. The other functions have a natural answer for an empty array and return it: `zero()` for the sums, `true` for `same_to` and `map_same_to`, `None` for `find`, and an empty array for `reverse`. Keep this split when adding functions, or document the exception.

## Allocation

`reverse`, `zero_arr`, `map_same` and `map_same_to` allocate a new array. `reverse_inplace` mutates its argument, and the other functions only read.

## Maintenance notes

- Update this page and the [API reference](../api/array_utils.md) whenever a function is added or removed, or its constraints or edge-case behaviour change, and regenerate `src/pkg.generated.mbti` with `moon info`.
- The doc comment of `reverse_inplace` in the source says that it panics on an empty array. It does not: the loop does not run, and the array is left unchanged.
