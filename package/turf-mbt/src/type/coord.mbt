///|
pub(open) trait CoordTrait: Add + Sub + Neg + Show {
  x(Self) -> Double
  y(Self) -> Double
  xy(Self) -> XY = _
  set_x(Self, Double) -> Self
  set_y(Self, Double) -> Self
  /// Due to Moonbit's current specification, implementing multiplication and division across different types is impossible.
  /// Therefore, we will not use the Mul trait or Div trait, but instead define our own functions.
  mul(Self, Double) -> Self
  /// Due to Moonbit's current specification, implementing multiplication and division across different types is impossible.
  /// Therefore, we will not use the Mul trait or Div trait, but instead define our own functions.
  div(Self, Double) -> Self
  dot(Self, Self) -> Double = _
}

///|
impl CoordTrait with xy(self) {
  XY::new(self.x(), self.y())
}

///|
impl CoordTrait with dot(self, other) {
  self.x() * other.x() + self.y() * other.y()
}
