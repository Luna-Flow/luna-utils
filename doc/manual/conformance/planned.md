# Planned packages and their standards

These packages are not implemented yet; the table records the standard each one is measured against so the checklist counts them as gaps. Floating point is measured against IEEE 754-2019 and integers against ISO/IEC 10967-1:2012 (LIA-1), whose integer clauses are cited below; LIA-1 may be extended to floating point later. The clause numbers come from the standard; its text is not reproduced here. `Level` is `required` for "shall" and `recommended` for "should".

## Clause traceability

| Clause | Level | API | Evidence | Status |
| --- | --- | --- | --- | --- |
| ISO/IEC 10967-1:2012 §5.1.1 integer result function: overflow is notified, never a silent wrong value (package `int`) | required | none | none | not implemented; [#21](https://github.com/Luna-Flow/luna-utils/issues/21) |
| ISO/IEC 10967-1:2012 §5.1.2.1 integer comparisons (package `int`) | required | host `==` and `<` on `Int`, `Int64`, `UInt` and `UInt64` | compiler matrix (`tools/compiler_matrix.py`) | partial: host operators only, no named operations; [#21](https://github.com/Luna-Flow/luna-utils/issues/21) |
| ISO/IEC 10967-1:2012 §5.1.2.2 neg, add, sub, mul, abs, signum with an overflow notification (package `int`) | required | none (host operators wrap) | none | not implemented; [#21](https://github.com/Luna-Flow/luna-utils/issues/21) |
| ISO/IEC 10967-1:2012 §5.1.2.2 quot (floor division) and mod (package `int`) | required | none (host `/` and `%` truncate) | none | not implemented; [#21](https://github.com/Luna-Flow/luna-utils/issues/21) |
| ISO/IEC 10967-1:2012 §5.3.1 integer to integer conversions (package `int`) | required | none | none | not implemented; [#21](https://github.com/Luna-Flow/luna-utils/issues/21) |
| ISO/IEC 10967-1:2012 §5.3.2, §5.3.3 floating point to integer and integer to floating point conversions | required | the conversions of the `float` packages | the convertToInteger and convertFromInt rows of [float](./float.md#clause-traceability) | partial: see those rows |
| IEEE 754-2019 §5.12 decimal and hexadecimal character conversion (package `text`) | required | none | none | not implemented; [#27](https://github.com/Luna-Flow/luna-utils/issues/27) |
| IEEE 754-2019 §5.4.1, §7.4 correctly rounded BigInt to binary conversion (package `bigint`) | required | none | none | not implemented; [#28](https://github.com/Luna-Flow/luna-utils/issues/28) |
| IEEE 754-2019 §9.2 correctly rounded elementary functions (package `math`) | recommended | none | none | not implemented; [#30](https://github.com/Luna-Flow/luna-utils/issues/30) |
| Stable seeded hash, identical on every backend (package `hash`; no standard clause) | required | none | none | not implemented; [#26](https://github.com/Luna-Flow/luna-utils/issues/26) |
