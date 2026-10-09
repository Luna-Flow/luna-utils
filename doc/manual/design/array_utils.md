# Array migration design

Removing the legacy helpers breaks the dependency from luna-utils to luna-generic, allowing luna-utils to become the bottom numeric layer. No compatibility wrapper or replacement trait is introduced. Applications own their folds, identities, overflow policy and empty-input policy.

For a finite array of length n, core fold, all, search and iterator extrema visit at most n elements and terminate when their callbacks terminate. They take O(n) time and O(1) auxiliary space; all and search may stop early. Reversal takes O(n) time: rev allocates O(n) output, rev_in_place uses O(1) auxiliary space. Array construction requires a nonnegative representable length and available memory.

Known downstream: calculus-numerical <= 0.3.1 used the old helpers; its WIP has a local legacy copy. Audit import sites before upgrading. Issue #6 becomes obsolete when arr_abs_sum is removed, rather than being fixed by a new numeric algorithm.

Implementation evidence: migration examples were checked with moon 0.1.20260920, moonc v0.10.14 and bundled core 0.10.14+7d59c7ec9. The relevant core sources are builtin/array.mbt, builtin/iterator.mbt, builtin/int.mbt, builtin/double.mbt and cmp/cmp.mbt. See the [official MoonBit documentation](https://docs.moonbitlang.com/en/latest/) for language and package rules. These are version-specific implementation observations, not formal verification or a standards-conformance proof.
