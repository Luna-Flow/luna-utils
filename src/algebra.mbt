///|
pub(open) trait MonoidAdd {
  op_add(Self, Self) -> Self
  zero() -> Self
}

///|
pub impl MonoidAdd for Int with zero() -> Int {
  0
}

///|
pub impl MonoidAdd for Double with zero() -> Double {
  0.0
}

///|
pub impl MonoidAdd for Bool with zero() -> Bool {
  false
}

///|
pub impl MonoidAdd for Bool with op_add(self : Bool, other : Bool) -> Bool {
  self || other
}

///|
pub(open) trait AbelianGroup: MonoidAdd {
  op_neg(Self) -> Self
}

///|
impl AbelianGroup for Bool with op_neg(self : Bool) -> Bool {
  not(self)
}

///|
pub fn abs[A : AbelianGroup + Compare](a : A) -> A {
  if a < A::zero() {
    -a
  } else {
    a
  }
}

///|
pub(open) trait MonoidMul {
  op_mul(Self, Self) -> Self
  one() -> Self
}

///|
pub impl MonoidMul for Int with one() -> Int {
  1
}

///|
pub impl MonoidMul for Double with one() -> Double {
  1.0
}

///|
pub impl MonoidMul for Bool with one() -> Bool {
  true
}

///|
pub impl MonoidMul for Bool with op_mul(self : Bool, other : Bool) -> Bool {
  self && other
}

///|
pub(open) trait Semiring: MonoidAdd + MonoidMul {}
