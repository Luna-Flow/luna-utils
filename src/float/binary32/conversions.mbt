/// Checked and saturating conversions from binary32 values.
///
/// A binary32 value converts exactly to binary64 before the shared conversion
/// implementation is called, so the range and rounding rules are identical.

pub fn to_int_checked(x : Float) -> Int? {
  @binary64.to_int_checked(x.to_double())
}

pub fn to_int_checked_with(x : Float, direction : @binary64.RoundingDirection) -> Int? {
  @binary64.to_int_checked_with(x.to_double(), direction)
}

pub fn to_int_saturating(x : Float) -> Int {
  @binary64.to_int_saturating(x.to_double())
}

pub fn to_int_saturating_with(x : Float, direction : @binary64.RoundingDirection) -> Int {
  @binary64.to_int_saturating_with(x.to_double(), direction)
}

pub fn to_int64_checked(x : Float) -> Int64? {
  @binary64.to_int64_checked(x.to_double())
}

pub fn to_int64_checked_with(x : Float, direction : @binary64.RoundingDirection) -> Int64? {
  @binary64.to_int64_checked_with(x.to_double(), direction)
}

pub fn to_int64_saturating(x : Float) -> Int64 {
  @binary64.to_int64_saturating(x.to_double())
}

pub fn to_int64_saturating_with(x : Float, direction : @binary64.RoundingDirection) -> Int64 {
  @binary64.to_int64_saturating_with(x.to_double(), direction)
}

pub fn to_uint_checked(x : Float) -> UInt? {
  @binary64.to_uint_checked(x.to_double())
}

pub fn to_uint_checked_with(x : Float, direction : @binary64.RoundingDirection) -> UInt? {
  @binary64.to_uint_checked_with(x.to_double(), direction)
}

pub fn to_uint_saturating(x : Float) -> UInt {
  @binary64.to_uint_saturating(x.to_double())
}

pub fn to_uint_saturating_with(x : Float, direction : @binary64.RoundingDirection) -> UInt {
  @binary64.to_uint_saturating_with(x.to_double(), direction)
}

pub fn to_uint64_checked(x : Float) -> UInt64? {
  @binary64.to_uint64_checked(x.to_double())
}

pub fn to_uint64_checked_with(x : Float, direction : @binary64.RoundingDirection) -> UInt64? {
  @binary64.to_uint64_checked_with(x.to_double(), direction)
}

pub fn to_uint64_saturating(x : Float) -> UInt64 {
  @binary64.to_uint64_saturating(x.to_double())
}

pub fn to_uint64_saturating_with(x : Float, direction : @binary64.RoundingDirection) -> UInt64 {
  @binary64.to_uint64_saturating_with(x.to_double(), direction)
}
