# Planned packages and their standards

These packages are not implemented yet; the table records the standard each one is measured against so the checklist counts them as gaps. IEEE 754-2019 is the standard of reference; it defines no integer arithmetic, so the `int` row has no external clause and the package defines its semantics in its design page and checks them against exact integers. `Level` is `required` for "shall" and `recommended` for "should".

## Clause traceability

| Clause | Level | API | Evidence | Status |
| --- | --- | --- | --- | --- |
| Integer arithmetic with defined overflow and division behavior (package `int`; IEEE 754 has no integer arithmetic, the semantics come from the package design and are checked against exact integers) | required | none | none | not implemented; [#21](https://github.com/Luna-Flow/luna-utils/issues/21) |
| IEEE 754-2019 §5.12 decimal and hexadecimal character conversion (package `text`) | required | none | none | not implemented; [#27](https://github.com/Luna-Flow/luna-utils/issues/27) |
| IEEE 754-2019 §5.4.1, §7.4 correctly rounded BigInt to binary conversion (package `bigint`) | required | none | none | not implemented; [#28](https://github.com/Luna-Flow/luna-utils/issues/28) |
| IEEE 754-2019 §9.2 correctly rounded elementary functions (package `math`) | recommended | none | none | not implemented; [#30](https://github.com/Luna-Flow/luna-utils/issues/30) |
| Stable seeded hash, identical on every backend (package `hash`; no standard clause) | required | none | none | not implemented; [#26](https://github.com/Luna-Flow/luna-utils/issues/26) |
