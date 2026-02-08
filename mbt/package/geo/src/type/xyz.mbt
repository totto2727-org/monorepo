///|
pub struct XYZ {
  x : Double
  y : Double
  z : Double
} derive(Show, Eq)

///|
pub fn XYZ::new(x : Double, y : Double, z : Double) -> XYZ {
  { x, y, z }
}

///|
pub impl Coord2DTrait for XYZ with x(self) {
  self.x
}

///|
pub impl Coord2DTrait for XYZ with y(self) {
  self.y
}

///|
pub impl Coord2DTrait for XYZ with set_x(self, x) {
  { ..self, x, }
}

///|
pub impl Coord2DTrait for XYZ with set_y(self, y) {
  { ..self, y, }
}

///|
pub impl Neg for XYZ with neg(self) {
  { x: -self.x, y: -self.y, z: -self.z }
}

///|
pub impl Add for XYZ with add(self, other) {
  { x: self.x + other.x, y: self.y + other.y, z: self.z + other.z }
}

///|
pub impl Sub for XYZ with sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y, z: self.z - other.z }
}

///|
pub impl CoordTrait for XYZ with mul(self, scalar) {
  { x: self.x * scalar, y: self.y * scalar, z: self.z * scalar }
}

///|
pub impl CoordTrait for XYZ with div(self, scalar) {
  { x: self.x / scalar, y: self.y / scalar, z: self.z / scalar }
}

///|
pub impl CoordTrait for XYZ with dot(self, other) {
  self.x * other.x + self.y * other.y + self.z * other.z
}

///|
pub impl Coord3DTrait for XYZ with z(self) {
  self.z
}

///|
pub impl Coord3DTrait for XYZ with set_z(self, z) {
  { ..self, z, }
}
