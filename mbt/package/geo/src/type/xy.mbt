///|
pub struct XY {
  x : Double
  y : Double
} derive(Show, Eq)

///|
pub fn XY::new(x : Double, y : Double) -> XY {
  XY::{ x, y }
}

///|
pub impl Coord2DTrait for XY with x(self) {
  self.x
}

///|
pub impl Coord2DTrait for XY with y(self) {
  self.y
}

///|
pub impl Coord2DTrait for XY with set_x(self, x) {
  XY::new(x, self.y)
}

///|
pub impl Coord2DTrait for XY with set_y(self, y) {
  XY::new(self.x, y)
}

///|
pub impl Neg for XY with neg(self) {
  XY::new(-self.x, -self.y)
}

///|
pub impl Add for XY with add(self, other) {
  XY::new(self.x + other.x, self.y + other.y)
}

///|
pub impl Sub for XY with sub(self, other) {
  XY::new(self.x - other.x, self.y - other.y)
}

///|
pub impl CoordTrait for XY with mul(self, other) {
  XY::new(self.x * other, self.y * other)
}

///|
pub impl CoordTrait for XY with div(self, other) {
  XY::new(self.x / other, self.y / other)
}

///|
pub impl CoordTrait for XY with dot(self, other) {
  self.x() * other.x() + self.y() * other.y()
}
