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
pub fn Rect::Rect(c1 : Coord, c2 : Coord) -> Rect {
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
  Rect::{ min: Coord(min_x, min_y), max: Coord(max_x, max_y) }
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
  Coord(
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
/// Returns the four edges of the rectangle as `Line` segments, walked CCW
/// starting from the `min` corner: `bl→br, br→tr, tr→tl, tl→bl`.
///
/// Mirrors `Triangle::to_lines` for symmetry and matches the upstream
/// `geo_types` API surface (the algorithm-layer helper
/// `lines_of_rect` is now a thin wrapper around this method).
pub fn Rect::to_lines(self : Rect) -> Array[Line] {
  let bl = Coord(self.min.x(), self.min.y())
  let br = Coord(self.max.x(), self.min.y())
  let tr = Coord(self.max.x(), self.max.y())
  let tl = Coord(self.min.x(), self.max.y())
  [
    Line::Line(bl, br),
    Line::Line(br, tr),
    Line::Line(tr, tl),
    Line::Line(tl, bl),
  ]
}

///|
/// Converts the rectangle into a `Polygon` with the four corners (CCW from
/// `min`).
pub fn Rect::to_polygon(self : Rect) -> Polygon {
  let exterior = LineString::LineString([
    Coord(self.min.x(), self.min.y()),
    Coord(self.max.x(), self.min.y()),
    Coord(self.max.x(), self.max.y()),
    Coord(self.min.x(), self.max.y()),
    Coord(self.min.x(), self.min.y()),
  ])
  Polygon::Polygon(exterior, [])
}

///|
/// Splits the rectangle into two equal-width halves along the X-axis at the
/// midpoint. Returns `(left, right)` where `left.max.x == right.min.x` is
/// the shared mid-X. The shared mid coordinate is computed once and reused
/// in both halves so floating-point round-off is bit-identical on the seam.
///
/// Mirrors Rust upstream `geo_types::Rect::split_x` (which returns a
/// `[Rect<T>; 2]` fixed-length array; a tuple is the closest MoonBit
/// equivalent that preserves the "exactly two" type-level guarantee).
pub fn Rect::split_x(self : Rect) -> (Rect, Rect) {
  let mid_x = (self.min.x() + self.max.x()) / 2.0
  let left = Rect::Rect(self.min, Coord(mid_x, self.max.y()))
  let right = Rect::Rect(Coord(mid_x, self.min.y()), self.max)
  (left, right)
}

///|
/// Splits the rectangle into two equal-height halves along the Y-axis at
/// the midpoint. Returns `(bottom, top)` where `bottom.max.y == top.min.y`
/// is the shared mid-Y. The shared mid coordinate is computed once and
/// reused in both halves so floating-point round-off is bit-identical on
/// the seam.
///
/// Mirrors Rust upstream `geo_types::Rect::split_y`.
pub fn Rect::split_y(self : Rect) -> (Rect, Rect) {
  let mid_y = (self.min.y() + self.max.y()) / 2.0
  let bottom = Rect::Rect(self.min, Coord(self.max.x(), mid_y))
  let top = Rect::Rect(Coord(self.min.x(), mid_y), self.max)
  (bottom, top)
}
