# Float conformance and limits

The contract separates exact integer encodings from portable numeric observations. Raw tests cover every classification, signed zero, exponent boundaries, NaN quiet bits, both signs, payload width limits and signaling-zero rejection. Numeric tests use `x != x` for NaN and compare canonical integer output, never input NaN metadata.

Four-backend debug/release checks and exact transcript comparison follow the [CI contract](../testing.md). Local results cannot establish Linux GCC behavior; CI must confirm that job. Tests are regression evidence, not a proof of all IEEE 754 behavior. No Lean/mathlib formal proof is supplied.

Exception flags, FMA, conversions, IEEE extrema, rounding, stable hashing, formatting, bigint and libm remain separate issues. Canonicalization is an application representation policy; it is not a promise to preserve floating-point payloads across a host round trip.
