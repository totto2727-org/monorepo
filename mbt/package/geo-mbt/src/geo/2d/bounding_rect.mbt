// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/bounding_rect.rs

///|
/// Computes the axis-aligned bounding rectangle of an array of coordinates.
/// Returns `None` for an empty array.
fn bounding_rect_of_coords(coords : Array[@type.Coord]) -> @type.Rect? {
  if coords.length() == 0 {
    return None
  }
  let mut min_x = coords[0].x()
  let mut max_x = coords[0].x()
  let mut min_y = coords[0].y()
  let mut max_y = coords[0].y()
  for i = 1; i < coords.length(); i = i + 1 {
    let c = coords[i]
    if c.x() < min_x {
      min_x = c.x()
    }
    if c.x() > max_x {
      max_x = c.x()
    }
    if c.y() < min_y {
      min_y = c.y()
    }
    if c.y() > max_y {
      max_y = c.y()
    }
  }
  Some(@type.Rect::Rect(@type.Coord(min_x, min_y), @type.Coord(max_x, max_y)))
}

///|
/// Bounding rect of a `Coord` is a degenerate `Rect` of zero size.
pub fn bounding_rect_of_coord(c : @type.Coord) -> @type.Rect {
  @type.Rect::Rect(c, c)
}

///|
/// Bounding rect of a `Point` is a degenerate `Rect` of zero size.
pub fn bounding_rect_of_point(p : @type.Point) -> @type.Rect {
  @type.Rect::Rect(p.coord(), p.coord())
}

///|
pub fn bounding_rect_of_line(l : @type.Line) -> @type.Rect {
  @type.Rect::Rect(l.start(), l.end())
}

///|
pub fn bounding_rect_of_line_string(ls : @type.LineString) -> @type.Rect? {
  bounding_rect_of_coords(ls.coords())
}

///|
pub fn bounding_rect_of_multi_point(mp : @type.MultiPoint) -> @type.Rect? {
  bounding_rect_of_coords(coords_of_multi_point(mp))
}

///|
pub fn bounding_rect_of_multi_line_string(
  mls : @type.MultiLineString,
) -> @type.Rect? {
  bounding_rect_of_coords(coords_of_multi_line_string(mls))
}

///|
pub fn bounding_rect_of_polygon(p : @type.Polygon) -> @type.Rect? {
  bounding_rect_of_coords(p.exterior().coords())
}

///|
pub fn bounding_rect_of_multi_polygon(mp : @type.MultiPolygon) -> @type.Rect? {
  let coords = mp
    .polygons()
    .iter()
    .flat_map(fn(poly) { poly.exterior().coords().iter() })
    .collect()
  bounding_rect_of_coords(coords)
}

///|
pub fn bounding_rect_of_triangle(t : @type.Triangle) -> @type.Rect {
  match bounding_rect_of_coords(t.to_array()) {
    Some(r) => r
    None => abort("triangle should always have a bounding rect")
  }
}

///|
pub fn bounding_rect_of_rect(r : @type.Rect) -> @type.Rect {
  r
}

///|
pub fn bounding_rect_of_geometry_collection(
  gc : @type.GeometryCollection,
) -> @type.Rect? {
  let coords = coords_of_geometry_collection(gc)
  bounding_rect_of_coords(coords)
}

///|
/// Returns the bounding rectangle of the geometry, or `None` if it has no
/// coordinates.
pub fn bounding_rect_of_geometry(g : @type.Geometry) -> @type.Rect? {
  match g {
    @type.Geometry::Point(p) => Some(bounding_rect_of_point(p))
    @type.Geometry::Line(l) => Some(bounding_rect_of_line(l))
    @type.Geometry::Triangle(t) => Some(bounding_rect_of_triangle(t))
    @type.Geometry::Rect(r) => Some(bounding_rect_of_rect(r))
    @type.Geometry::LineString(ls) => bounding_rect_of_line_string(ls)
    @type.Geometry::MultiPoint(mp) => bounding_rect_of_multi_point(mp)
    @type.Geometry::MultiLineString(mls) =>
      bounding_rect_of_multi_line_string(mls)
    @type.Geometry::Polygon(p) => bounding_rect_of_polygon(p)
    @type.Geometry::MultiPolygon(mp) => bounding_rect_of_multi_polygon(mp)
    @type.Geometry::GeometryCollection(gc) =>
      bounding_rect_of_geometry_collection(gc)
  }
}
