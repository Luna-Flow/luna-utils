# Changelog

## 0.2.0 — Unreleased

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
