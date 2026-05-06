// Ported from georust/geo
// https://github.com/georust/geo/blob/main/geo/src/algorithm/orient.rs

///|
/// The convention for ring orientation in a `Polygon`.
pub(all) enum OrientDirection {
  /// CCW exterior, CW interiors (the default per the OGC SFA / GeoJSON
  /// canonical orientation).
  Default
  /// CW exterior, CCW interiors.
  Reversed
} derive(Eq, Debug)

///|
/// Returns a `LineString` with the requested winding order.
fn ensure_winding(
  ls : @type.LineString,
  desired : WindingOrder,
) -> @type.LineString {
  match winding_order(ls) {
    Some(actual) => if actual == desired { ls } else { reverse_line_string(ls) }
    None => ls
  }
}

///|
/// Returns a `Polygon` with the rings re-oriented per `direction`.
pub fn orient_polygon(
  polygon : @type.Polygon,
  direction : OrientDirection,
) -> @type.Polygon {
  let (exterior_winding, interior_winding) = match direction {
    Default => (WindingOrder::CounterClockwise, WindingOrder::Clockwise)
    Reversed => (WindingOrder::Clockwise, WindingOrder::CounterClockwise)
  }
  let exterior = ensure_winding(polygon.exterior(), exterior_winding)
  let interiors = polygon
    .interiors()
    .map(fn(i) { ensure_winding(i, interior_winding) })
  @type.Polygon::Polygon(exterior, interiors)
}

///|
/// Re-orient every polygon in a multi polygon.
pub fn orient_multi_polygon(
  mp : @type.MultiPolygon,
  direction : OrientDirection,
) -> @type.MultiPolygon {
  let polygons = mp.polygons().map(fn(p) { orient_polygon(p, direction) })
  @type.MultiPolygon::MultiPolygon(polygons)
}
