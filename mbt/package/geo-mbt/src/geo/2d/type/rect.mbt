// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/rect.rs

///|
/// An axis-aligned bounded 2D rectangle whose area is defined by minimum and
/// maximum `Coord`s.
///
/// The constructor normalises the input so that `min.x <= max.x` and
/// `min.y <= max.y`.
pub struct Rect {
  min : Coord
  max : Coord
} derive(Eq, Debug, Hash)

///|
/// Creates a new `Rect` from two coordinates. Order is not significant — the
/// resulting rectangle's `min`/`max` are the component-wise min/max of the
/// inputs.
pub fn Rect::new(c1 : Coord, c2 : Coord) -> Rect {
  let (min_x, max_x) = if c1.x() <= c2.x() {
    (c1.x(), c2.x())
  } else {
    (c2.x(), c1.x())
  }
  let (min_y, max_y) = if c1.y() <= c2.y() {
    (c1.y(), c2.y())
  } else {
    (c2.y(), c1.y())
  }
  Rect::{ min: Coord::new(min_x, min_y), max: Coord::new(max_x, max_y) }
}

///|
pub fn Rect::min(self : Rect) -> Coord {
  self.min
}

///|
pub fn Rect::max(self : Rect) -> Coord {
  self.max
}

///|
pub fn Rect::width(self : Rect) -> Double {
  self.max.x() - self.min.x()
}

///|
pub fn Rect::height(self : Rect) -> Double {
  self.max.y() - self.min.y()
}

///|
/// Returns the centroid of the rectangle.
pub fn Rect::center(self : Rect) -> Coord {
  Coord::new(
    (self.min.x() + self.max.x()) / 2.0,
    (self.min.y() + self.max.y()) / 2.0,
  )
}

///|
/// Returns the rectangle's signed area: `width * height`.
pub fn Rect::area(self : Rect) -> Double {
  self.width() * self.height()
}

///|
/// Converts the rectangle into a `Polygon` with the four corners (CCW from
/// `min`).
pub fn Rect::to_polygon(self : Rect) -> Polygon {
  let exterior = LineString::new([
    Coord::new(self.min.x(), self.min.y()),
    Coord::new(self.max.x(), self.min.y()),
    Coord::new(self.max.x(), self.max.y()),
    Coord::new(self.min.x(), self.max.y()),
    Coord::new(self.min.x(), self.min.y()),
  ])
  Polygon::new(exterior, [])
}
