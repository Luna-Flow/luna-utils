# Numeric base design

Future floating-point operations must define IEEE 754-2019 semantics; future integer operations must define ISO/IEC 10967-1 semantics. Definitions must state domain, exceptional inputs, rounding, error bounds, complexity and termination. Tests support those contracts but do not prove them. No such numeric implementation is added by the legacy removal.

Keep pure numeric transformations separate from flags and other effects. Backend independence must be checked on wasm, wasm-gc, js and native in debug and release, with Linux gcc and macOS clang. Issue #20 supplies the CI foundation; it does not turn empty-package builds into numeric conformance evidence.
