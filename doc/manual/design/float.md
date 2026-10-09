# Float representation design

For binary64, bit 63 is sign, bits 62–52 exponent and bits 51–0 fraction; bit 51 is the quiet bit. Binary32 uses sign bit 31, exponent bits 30–23, fraction bits 22–0 and quiet bit 22. An all-one exponent means infinity when the fraction is zero and NaN otherwise. An all-zero exponent means zero when the fraction is zero and subnormal otherwise; all remaining encodings are normal.

Raw operations use fixed-width integer masks. Classification cases are exhaustive and disjoint by the exponent/fraction partition. Sign operations preserve the magnitude mask by construction. Payload guards exclude fraction overflow and the signaling-zero infinity encoding. Every operation takes O(1) time and space with no loops or numeric rounding; termination follows from finite expressions.

A raw integer encoding preserves NaN sign, signaling state and payload exactly. A numeric value does not preserve that information portably, especially on JavaScript. Numeric NaN is detected by `x != x`; `portable_classify` returns `QuietNaN` without inspecting its sign or payload. `portable_is_signaling` is always false, while binary interchange `is_canonical_bits` and `portable_is_canonical` are always true. Keep signaling NaNs as integers when their representation matters.

IEEE 754-2019 §§5.7.2, 5.5.1 and 9.7 motivate classification, sign and payload operations; §6.2 does not require identical NaN payload propagation across hosts. This package makes its canonical encoding policy explicit. It does not raise IEEE exception flags or preserve numeric signaling NaNs. Current MoonBit core 0.10.14+7d59c7ec9 and official [language documentation](https://docs.moonbitlang.com/en/latest/) provide implementation evidence, not a formal verification claim.
