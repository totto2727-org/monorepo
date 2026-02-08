///|
pub(open) trait CoordTrait: Add + Sub + Neg + Show {
  /// Due to Moonbit's current specification, implementing multiplication and division across different types is impossible.
  /// Therefore, we will not use the Mul trait or Div trait, but instead define our own functions.
  mul(Self, Double) -> Self
  /// Due to Moonbit's current specification, implementing multiplication and division across different types is impossible.
  /// Therefore, we will not use the Mul trait or Div trait, but instead define our own functions.
  div(Self, Double) -> Self
  dot(Self, Self) -> Double
}

///|
pub(open) trait Coord2DTrait: CoordTrait {
  x(Self) -> Double
  y(Self) -> Double
  xy(Self) -> XY = _
  set_x(Self, Double) -> Self
  set_y(Self, Double) -> Self
}

///|
impl Coord2DTrait with xy(self) {
  XY::new(self.x(), self.y())
}

///|
pub(open) trait Coord3DTrait: Coord2DTrait {
  z(Self) -> Double
  xyz(Self) -> XYZ = _
  set_z(Self, Double) -> Self
}

///|
impl Coord3DTrait with xyz(self) {
  XYZ::new(self.x(), self.y(), self.z())
}
