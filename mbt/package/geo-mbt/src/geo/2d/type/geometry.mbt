// Ported from georust/geo-types
// https://github.com/georust/geo/blob/main/geo-types/src/geometry/mod.rs (the
// `Geometry` enum) and adapted to MoonBit's enum syntax.

///|
/// An enumeration of all geometry types except `Coord` (which is not itself a
/// "geometry" in the OGC sense).
pub(all) enum Geometry {
  Point(Point)
  Line(Line)
  LineString(LineString)
  Polygon(Polygon)
  MultiPoint(MultiPoint)
  MultiLineString(MultiLineString)
  MultiPolygon(MultiPolygon)
  GeometryCollection(GeometryCollection)
  Rect(Rect)
  Triangle(Triangle)
} derive(Eq, Debug)

///|
/// Raised by `Geometry::try_into_*` when the variant does not match the
/// expected one. Carries both the expected variant name and the actual
/// variant name observed, matching the upstream Rust `MismatchedGeometry`
/// error.
pub suberror MismatchedGeometry {
  MismatchedGeometry(expected~ : String, found~ : String)
} derive(Eq, Debug)

///|
/// Returns the variant name of the given geometry, used in error messages.
fn Geometry::variant_name(self : Geometry) -> String {
  match self {
    Point(_) => "Point"
    Line(_) => "Line"
    LineString(_) => "LineString"
    Polygon(_) => "Polygon"
    MultiPoint(_) => "MultiPoint"
    MultiLineString(_) => "MultiLineString"
    MultiPolygon(_) => "MultiPolygon"
    GeometryCollection(_) => "GeometryCollection"
    Rect(_) => "Rect"
    Triangle(_) => "Triangle"
  }
}

///|
/// If `self` is the `Point` variant, returns the inner `Point`. Otherwise
/// raises `MismatchedGeometry` with the expected / actual variant names.
/// Mirrors Rust upstream `TryFrom<Geometry> for Point` (`g.try_into()`).
pub fn Geometry::try_into_point(
  self : Geometry,
) -> Point raise MismatchedGeometry {
  match self {
    Point(p) => p
    other =>
      raise MismatchedGeometry(expected="Point", found=other.variant_name())
  }
}

///|
pub fn Geometry::try_into_line(
  self : Geometry,
) -> Line raise MismatchedGeometry {
  match self {
    Line(l) => l
    other =>
      raise MismatchedGeometry(expected="Line", found=other.variant_name())
  }
}

///|
pub fn Geometry::try_into_line_string(
  self : Geometry,
) -> LineString raise MismatchedGeometry {
  match self {
    LineString(ls) => ls
    other =>
      raise MismatchedGeometry(
        expected="LineString",
        found=other.variant_name(),
      )
  }
}

///|
pub fn Geometry::try_into_polygon(
  self : Geometry,
) -> Polygon raise MismatchedGeometry {
  match self {
    Polygon(p) => p
    other =>
      raise MismatchedGeometry(expected="Polygon", found=other.variant_name())
  }
}

///|
pub fn Geometry::try_into_multi_point(
  self : Geometry,
) -> MultiPoint raise MismatchedGeometry {
  match self {
    MultiPoint(mp) => mp
    other =>
      raise MismatchedGeometry(
        expected="MultiPoint",
        found=other.variant_name(),
      )
  }
}

///|
pub fn Geometry::try_into_multi_line_string(
  self : Geometry,
) -> MultiLineString raise MismatchedGeometry {
  match self {
    MultiLineString(mls) => mls
    other =>
      raise MismatchedGeometry(
        expected="MultiLineString",
        found=other.variant_name(),
      )
  }
}

///|
pub fn Geometry::try_into_multi_polygon(
  self : Geometry,
) -> MultiPolygon raise MismatchedGeometry {
  match self {
    MultiPolygon(mp) => mp
    other =>
      raise MismatchedGeometry(
        expected="MultiPolygon",
        found=other.variant_name(),
      )
  }
}

///|
/// Unlike the Rust upstream — which excludes `GeometryCollection` from its
/// `try_from_geometry_impl!` macro to avoid clashing with a deprecated
/// `From<single_geom> for GeometryCollection` impl — the port has no such
/// deprecated conversion, so the symmetry is preserved here.
pub fn Geometry::try_into_geometry_collection(
  self : Geometry,
) -> GeometryCollection raise MismatchedGeometry {
  match self {
    GeometryCollection(gc) => gc
    other =>
      raise MismatchedGeometry(
        expected="GeometryCollection",
        found=other.variant_name(),
      )
  }
}

///|
pub fn Geometry::try_into_rect(
  self : Geometry,
) -> Rect raise MismatchedGeometry {
  match self {
    Rect(r) => r
    other =>
      raise MismatchedGeometry(expected="Rect", found=other.variant_name())
  }
}

///|
pub fn Geometry::try_into_triangle(
  self : Geometry,
) -> Triangle raise MismatchedGeometry {
  match self {
    Triangle(t) => t
    other =>
      raise MismatchedGeometry(expected="Triangle", found=other.variant_name())
  }
}
