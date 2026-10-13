# Changelog

## Unreleased

### Added

- The `int` rows of the planned-packages conformance table cite ISO/IEC 10967-1:2012 (LIA-1) §5.1.1, §5.1.2.1, §5.1.2.2 and §5.3: overflow of neg, add, sub, mul and abs is notified, division is floor division with a floor mod (truncating division is not recommended by the standard), and integer to integer conversions report overflow. Floating point stays measured against IEEE 754-2019; LIA-1 may be extended to it later.
- Standards conformance: `doc/manual/conformance/float.md` has a clause traceability table for IEEE 754-2019 (28 clauses of `float` and `float/binary32` with level, API, evidence and status), `planned.md` lists the standards the planned packages are measured against, and `checklist.md` is a generated checklist with counts of required and recommended gaps (`tools/conformance_checklist.py`, which also fails when a table cites a missing path; the pull request CI fails when the checklist is stale). The gaps are ordered by the roadmap in [#50](https://github.com/Luna-Flow/luna-utils/issues/50): finish the partial clauses, then the missing required ones, then the recommended and optional ones.
- Compiler matrix: `tools/compiler_matrix.py` and `tools/run_matrix.py` run the numeric types Luna-Flow uses through eleven storage forms and about two dozen operations, comparing storage forms, debug against release and (for integers, `Bool` and `Char`) all backends without an external oracle; `tools/usage_census.py` records which types, containers and operations the Luna-Flow sources use. It runs in pull request CI and in the daily workflow. The first full run (144,672 cells on four backends in debug and release) found only the already tracked [#42](https://github.com/Luna-Flow/luna-utils/issues/42).
- Randomized audit platform: `tools/random_audit.py` (seeded cases with exact `fractions` models for every public `float` and `float/binary32` function), `tools/run_audit.py` (debug and release on one backend), `tools/api_audit.py` (every public function must be exercised), `tools/mutation_check.py` (injected bugs must be noticed), `tools/known_issues.json`, `tools/audit_report.py`, a fixed-seed audit in the pull request CI and a nightly workflow that runs a date-seeded audit on all five configurations and publishes one report. See the manual page on backend conformance testing.
- The first audit run found [#42](https://github.com/Luna-Flow/luna-utils/issues/42): on the native backend in release mode a `UInt?` payload is sign-extended when widened with `to_uint64`. It is independent of this package and is tracked in the known-issues list.
- `Luna-Flow/luna-utils/float` and `Luna-Flow/luna-utils/float/binary32`: sixteen
  portable integer conversions per package, `to_{int,int64,uint,uint64}_checked`
  and `to_{int,int64,uint,uint64}_saturating`, each with a `_with` form that takes
  a `RoundingDirection`. The value is rounded first (the forms without `_with`
  round toward zero) and the range is decided on the rounded integer. NaN and the
  infinities give `None` (checked) or `0`/the nearest bound (saturating), both
  zeros convert to `0`, and out-of-range values never reach a core primitive, so
  results are identical on wasm, wasm-gc, js and native.
- `@float.int64_to_float` and `@float.uint64_to_float`: `Int64`/`UInt64` to
  binary32 `Float`, rounded once to nearest-even. They are the backend-independent
  counterpart of core `Float::from_int64`/`Float::from_uint64`, which follow each
  backend's own conversion (on js through binary64, so they round twice). They return a binary32
  `Float` and live in `@float`; their placement is open for the maintainer.
- Tests: table-driven offline oracle (exact `fractions`/integer arithmetic) for the
  conversions in both formats, including halfway inputs, the `2^k` sweep and
  carry cases, plus the default-direction functions; the fixtures are folded into
  compact transcript records. `.moonignore` keeps fixtures, tools, CI files and
  `src/ci_probe` out of the published package.
- Manual (API, design, tutorial, conformance, testing) and zh_CN/ja_JP catalogs.

### Fixed

- The published package no longer includes `ready_to_pr.sh`, and CI now runs `tools/check_package_contents.py`, which builds the package and fails if `src/ci_probe/`, `testdata/`, `tools/` or `ready_to_pr.sh` are in it.
- `int64_to_float`/`uint64_to_float` give `Int64`/`UInt64` to binary32 conversions that
  round once on every backend; core's `Float::from_int64`/`Float::from_uint64` follow
  each backend, so on js they round twice (by design of core, not a bug).
  Closes [#22](https://github.com/Luna-Flow/luna-utils/issues/22).

## 0.2.0 — 2026-10-11

Breaking rebuild: retain the luna-utils name, remove the 0.1.x public API and
Luna-Flow/luna-generic dependency, and depend only on moonbitlang/core.
The root public API is empty at this stage. Float representation is available
through #25, and round-to-integral directions are added by #24. Remaining
numeric work is tracked in #19; #30 places libm in the `math` subpackage.

| Removed API | Migration candidate |
| --- | --- |
| `arr_sum` | `xs.fold(init=zero, (a, b) => a + b)` |
| `zero_arr` | `Array::make(n, zero)` |
| `arr_abs_sum` | fold with a type-supported `abs` |
| `reverse` / `reverse_inplace` | `Array::rev` / `Array::rev_in_place` |
| `find` | `Array::search` |
| `same` / `same_to` / `map_same` / `map_same_to` | `Array::all` with explicit sample/empty-input policy |
| `arr_max` / `arr_min` | `iter().maximum()` / `iter().minimum()` returning `T?` |
| `clamp` | type-provided clamp, or `@cmp.maximum(lo, @cmp.minimum(v, hi))` |
| `is_between` | `lo <= v && v <= hi` |

These candidates are not full numeric semantic equivalents. See the manual
for empty input, mapping evaluation order, Int minimum/overflow, NaN, signed
zero and reversed bounds. Known downstream calculus-numerical <= 0.3.1 needs
migration; its WIP already carries local legacy helpers. Removing arr_abs_sum
makes issue #6 obsolete once this change is merged.

The existing manual URLs now explain migration; English gettext source and
zh_CN/ja_JP translations are synchronized.

CI: debug/release four-backend conformance gates, Linux GCC and macOS Clang
native checks with FP contraction disabled, exact bit transcript comparison,
offline binary64 oracle fixtures, a release-proof FP contraction probe, a pinned
MoonBit toolchain, and coverage artifacts (#20).

Added `float` (binary64) and `float/binary32`: raw-bit classification and
predicates, canonical NaN encodings, exact sign operations, checked integer
payload adapters, numeric NaN normalization and radix. Numeric APIs discard
NaN sign/payload/signaling metadata; integer APIs preserve it. No exception
flags or host payload round-trip guarantee is introduced.

Review corrections for #25: every binary encoding is IEEE-canonical, including NaNs. NaN-normalized numeric sign and classification functions use `portable_*` names; raw integer operations retain IEEE encoding semantics. Independent offline integer oracles now cover both widths in the CI transcripts.

Added: [#24](https://github.com/Luna-Flow/luna-utils/issues/24) adds all five IEEE 754-2019 §5.9 round-to-integral directions for binary64 and binary32, with shared `RoundingDirection` dispatch and an exact `Fraction` value oracle. sNaN invalid and inexact flag reporting remain scoped to [#29](https://github.com/Luna-Flow/luna-utils/issues/29).

Added: [#23](https://github.com/Luna-Flow/luna-utils/issues/23) adds IEEE 754-2019 §9.6 `minimum`/`maximum`, §5.10 raw-bit `total_order_bits` and portable-value `portable_total_order`, and total-order sorting for arrays and mutable views in binary64 and binary32. Numeric NaNs follow the canonical representation policy; raw bit ordering preserves their sign, signaling state and payload.
