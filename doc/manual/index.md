# luna-utils

`luna-utils` is a small utility package for Luna-Flow projects. It provides array helpers and comparison helpers whose numeric constraints come from the traits of [luna-generic](https://luna-flow.github.io/en/luna-generic/), so they work for any type that implements the required structure.

## Public functions

The package exports only functions; it defines no types or traits of its own.

| Function | Constraint | Behaviour |
| --- | --- | --- |
| `arr_sum` | `AddMonoid` | Sum of the elements; `zero()` for an empty array. |
| `arr_abs_sum` | `Num + Compare` | Sum of the absolute values of the elements. |
| `zero_arr` | `AddMonoid` | Array of length `n` filled with `zero()`. |
| `arr_max`, `arr_min` | `Compare` | Largest or smallest element; panics on an empty array. |
| `find` | `Eq` | Index of the first occurrence of a value, or `None`. |
| `reverse` | none | New array with the elements in reverse order. |
| `reverse_inplace` | none | Reverses an array in place. |
| `same` | `Eq` | Whether all elements equal the first; panics on an empty array. |
| `same_to` | `Eq` | Whether all elements equal a given sample. |
| `map_same`, `map_same_to` | `Eq` on the result | `same` and `same_to` applied to the mapped array. |
| `clamp` | `Compare` | Restricts a value to the closed range from `min` to `max`. |
| `is_between` | `Compare` | Whether a value lies in the closed range from `min` to `max`. |

The interface file [pkg.generated.mbti](../../src/pkg.generated.mbti) is the authoritative list of signatures, and the generated API documentation is on [mooncakes.io](https://mooncakes.io/docs/Luna-Flow/luna-utils).

## Contributing

Code style, naming, commit and review rules are in the [contribution guidelines](contributing.md).
