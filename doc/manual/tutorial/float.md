# Float representation tutorial

Import `Luna-Flow/luna-utils/float` as `f64` and `Luna-Flow/luna-utils/float/binary32` as `f32` in moon.pkg. Keep a signaling NaN as an integer and canonicalize at a numeric serialization boundary.

```moonbit
assert_true(@f64.is_signaling_bits(0x7ff0000000000001UL))
assert_eq(@f64.get_payload_bits(0x7ff0000000000001UL), Some(1UL))
assert_eq(@f64.abs_bits(0xfff0000000000001UL), 0x7ff0000000000001UL)
assert_eq(@f64.to_bits_canonical(0.0 / 0.0), 0x7ff8000000000000UL)
assert_eq(@f32.canonicalize_nan_bits(0xff800001U), 0x7fc00000U)
assert_eq(@f32.negate_bits(0U), 0x80000000U)
assert_eq(@f64.radix(), 2)
assert_eq(@f64.round_ties_even(2.5), 2.0)
assert_eq(@f64.round_ties_away(-2.5), -3.0)
assert_eq(
  @f32.round_to_integral(2.5F, @f64.TowardPositive),
  3.0F,
)
assert_eq(@f64.to_bits_canonical(@f64.minimum(0.0, -0.0)), 0x8000000000000000UL)
assert_eq(@f32.to_bits_canonical(@f32.maximum(-0.0, 0.0)), 0U)
assert_true(@f64.total_order(-0.0, 0.0))
assert_true(@f64.total_order_bits(0xfff0000000000001UL, 0xfff0000000000000UL))
let values = [3.0, -0.0, 0.0, -2.0]
@f64.sort_total_order(values)
assert_eq(values, [-2.0, -0.0, 0.0, 3.0])
```

Use the raw payload setters to construct encodings, check `None`, and avoid converting the result through Double or Float when payload fidelity matters. Canonical numeric functions intentionally discard NaN metadata. See the [API](../api/float.md) and [conformance limits](../conformance/float.md).
