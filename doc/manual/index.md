# luna-utils

Version 0.2.0 is a breaking rebuild of the numeric base for Luna-Flow. The module depends only on `moonbitlang/core`; the legacy array and comparison API has been removed. At this migration stage the root package exports no functions, types or traits.

The backend-independent numeric packages are planned in [tracking issue #19](https://github.com/Luna-Flow/luna-utils/issues/19). Integer arithmetic, conversions, IEEE extrema, rounding, classification, stable hash, text, bigint, software FMA and libm (#21–#30) are not implemented by this change. The placement of libm remains undecided.

The generated interface [pkg.generated.mbti](../../src/pkg.generated.mbti) is the public-name authority for this checkout. Published Mooncakes documentation may still describe an older release. Source filenames are not MoonBit package boundaries.

## Migration manual

Existing page paths remain available as migration guidance: array [API](api/array_utils.md), [design](design/array_utils.md), [tutorial](tutorial/array_utils.md); comparison [API](api/comparison.md), [design](design/comparison.md), [tutorial](tutorial/comparison.md). See the [contribution checklist](contributing.md) before opening a pull request.
