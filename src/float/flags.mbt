///|
/// The five exception flags of IEEE 754-2019 §7. Operations with a `_flags` suffix return their
/// value together with the flags it raises; the package has no global status word, so flags
/// are plain values that the caller combines.
pub(all) struct Flags {
  invalid : Bool
  divide_by_zero : Bool
  overflow : Bool
  underflow : Bool
  inexact : Bool
} derive(Eq, Debug)

///|
pub extend Flags with Eq::{equal, not_equal}

///|
pub extend Flags with @debug.Debug::{to_repr}

///|
/// No flag raised.
pub fn Flags::none() -> Flags {
  {
    invalid: false,
    divide_by_zero: false,
    overflow: false,
    underflow: false,
    inexact: false,
  }
}

///|
/// True when no flag is raised.
pub fn Flags::is_empty(self : Flags) -> Bool {
  self == Flags::none()
}

///|
/// The union of two flag sets.
pub fn Flags::combine(self : Flags, other : Flags) -> Flags {
  {
    invalid: self.invalid || other.invalid,
    divide_by_zero: self.divide_by_zero || other.divide_by_zero,
    overflow: self.overflow || other.overflow,
    underflow: self.underflow || other.underflow,
    inexact: self.inexact || other.inexact,
  }
}

///|
/// The flags in the bit layout of Berkeley TestFloat: inexact 1, underflow 2, overflow 4,
/// divide by zero 8, invalid 16.
pub fn Flags::to_bits(self : Flags) -> Int32 {
  (if self.inexact { 1 } else { 0 }) |
  (if self.underflow { 2 } else { 0 }) |
  (if self.overflow { 4 } else { 0 }) |
  (if self.divide_by_zero { 8 } else { 0 }) |
  (if self.invalid { 16 } else { 0 })
}

///|
/// Only the invalid operation flag raised.
pub fn Flags::invalid_only() -> Flags {
  { ..Flags::none(), invalid: true, }
}
