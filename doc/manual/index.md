# luna-utils

Version 0.2.0 is a breaking rebuild of the numeric base for Luna-Flow. The module depends only on `moonbitlang/core`; the legacy array and comparison API has been removed. At this migration stage the root package exports no functions, types or traits.

The numeric package roadmap is tracked in [issue #19](https://github.com/Luna-Flow/luna-utils/issues/19). Float representation APIs are available through [#25](https://github.com/Luna-Flow/luna-utils/issues/25), and this checkout adds round-to-integral directions through [#24](https://github.com/Luna-Flow/luna-utils/issues/24). Other planned work includes integer arithmetic, conversions, IEEE extrema, stable hash, text, bigint and software FMA. The decided location for libm is the `math` subpackage ([#30](https://github.com/Luna-Flow/luna-utils/issues/30)).

The generated interface [pkg.generated.mbti](../../src/pkg.generated.mbti) is the public-name authority for this checkout. Published Mooncakes documentation may still describe an older release. Source filenames are not MoonBit package boundaries.

## Migration manual

Existing page paths remain available as migration guidance: array [API](api/array_utils.md), [design](design/array_utils.md), [tutorial](tutorial/array_utils.md); comparison [API](api/comparison.md), [design](design/comparison.md), [tutorial](tutorial/comparison.md). See the [contribution checklist](contributing.md) before opening a pull request.

See [backend conformance testing](testing.md) for the CI contract, offline oracle corpus and local commands.

Float representation packages are available: [API](api/float.md), [design](design/float.md), [tutorial](tutorial/float.md) and [conformance](conformance/float.md). The root package remains empty; import the float subpackages explicitly.
