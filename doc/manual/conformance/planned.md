# Planned packages and their standards

These packages are not implemented yet; the table records the standard each one is measured against so the checklist counts them as gaps. Clause numbers for ISO/IEC 10967-1 (LIA-1) are filled in when the standard text is at hand. `Level` is `required` for "shall" and `recommended` for "should".

## Clause traceability

| Clause | Level | API | Evidence | Status |
| --- | --- | --- | --- | --- |
| LIA-1 integer operations and notifications (package `int`) | required | none | none | not implemented; [#21](https://github.com/Luna-Flow/luna-utils/issues/21) |
| IEEE 754-2019 §5.12 decimal and hexadecimal character conversion (package `text`) | required | none | none | not implemented; [#27](https://github.com/Luna-Flow/luna-utils/issues/27) |
| IEEE 754-2019 §5.4.1, §7.4 correctly rounded BigInt to binary conversion (package `bigint`) | required | none | none | not implemented; [#28](https://github.com/Luna-Flow/luna-utils/issues/28) |
| IEEE 754-2019 §9.2 correctly rounded elementary functions (package `math`) | recommended | none | none | not implemented; [#30](https://github.com/Luna-Flow/luna-utils/issues/30) |
| Stable seeded hash, identical on every backend (package `hash`; no standard clause) | required | none | none | not implemented; [#26](https://github.com/Luna-Flow/luna-utils/issues/26) |
