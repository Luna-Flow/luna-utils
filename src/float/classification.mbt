///|
/// IEEE binary interchange classes. Use raw bits to observe signaling NaNs.
#derive(Eq, Debug)
pub(all) enum Classification {
  SignalingNaN
  QuietNaN
  PositiveInfinity
  NegativeInfinity
  PositiveNormal
  NegativeNormal
  PositiveSubnormal
  NegativeSubnormal
  PositiveZero
  NegativeZero
}

///|
pub extend Classification with Eq::{equal, not_equal}

///|
pub extend Classification with @debug.Debug::{to_repr}
