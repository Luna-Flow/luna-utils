# Float conformance and limits

The contract separates exact integer encodings from portable numeric observations. Raw tests cover every classification, signed zero, exponent boundaries, NaN quiet bits, both signs, payload width limits and signaling-zero rejection. Rounding tests cover all five IEEE 754-2019 §5.9 directions, positive and negative ties, the predecessor of 0.5, negative zero, large integral values and infinities. Numeric tests use `x != x` for NaN and compare canonical integer output, never input NaN metadata.

Four-backend debug/release checks and exact transcript comparison follow the [CI contract](../testing.md). Local results cannot establish Linux GCC behavior; CI must confirm that job. Tests are regression evidence, not a proof of all IEEE 754 behavior. No Lean/mathlib formal proof is supplied.

Exception flags, FMA, conversions, IEEE extrema, stable hashing, formatting, bigint and libm remain separate issues. Exact inexact-flag reporting for rounding waits for [issue #29](https://github.com/Luna-Flow/luna-utils/issues/29). Canonicalization is an application representation policy; it is not a promise to preserve floating-point payloads across a host round trip.
