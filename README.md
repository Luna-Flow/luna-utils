# luna-utils

Version 0.2.0 rebuilds the backend-independent numeric base for Luna-Flow.
It depends only on [moonbitlang/core](https://github.com/moonbitlang/core).
This migration removes all 0.1.x array/comparison helpers: the root package
currently exports no functions, types or traits. The float and float/binary32 subpackages provide classification, NaN
canonicalization and exact integer bit operations (#25). Other numeric packages
in [tracking issue #19](https://github.com/Luna-Flow/luna-utils/issues/19) remain planned;
this release boundary does not claim implemented IEEE 754 or integer conformance.

## Migration and documentation

See [CHANGELOG](./CHANGELOG.md), the [manual](./doc/manual/index.md),
[array migration](./doc/manual/api/array_utils.md) and
[comparison migration](./doc/manual/api/comparison.md) before upgrading.
Core substitutions change empty-input, overflow, NaN and invalid-bound behavior;
they are not blanket semantic equivalents.

The manual is published at
[luna-flow.github.io/en/luna-utils](https://luna-flow.github.io/en/luna-utils/)
with Simplified Chinese and Japanese translations. English source lives in
[doc/manual](./doc/manual/index.md); translations are gettext catalogs in
`doc/locale`. See the [contribution checklist](./doc/manual/contributing.md).

See [backend conformance testing](doc/manual/testing.md) for the CI contract,
offline oracle corpus and local commands.

See the [float API](doc/manual/api/float.md), [tutorial](doc/manual/tutorial/float.md)
and [conformance limits](doc/manual/conformance/float.md). NaN metadata is
preserved only by integer encoding APIs, not numeric host round trips.
