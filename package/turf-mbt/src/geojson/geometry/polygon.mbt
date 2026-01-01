///|
pub suberror InvalidPolygonError String derive(Show, Eq, Compare, Hash)

///|
// TODO: Implement topological validation (RFC 7946 Section 3.1.6):
// - Winding Order: Exterior rings CCW, Interior rings CW (Right-Hand Rule)
// - Containment: Interior rings must be within Exterior ring, No overlapping holes
// - Self-intersection: Individual rings must not self-intersect
fn check_linear_ring(
  ring : Array[@position.Position],
) -> Unit raise InvalidPolygonError {
  if ring.length() < 4 {
    raise InvalidPolygonError(
      "Each LinearRing of a Polygon must have 4 or more Positions.",
    )
  }
  if ring[0] != ring[ring.length() - 1] {
    raise InvalidPolygonError("First and last Position are not equivalent.")
  }
}

///|
/// Polygon geometry object.
/// https://tools.ietf.org/html/rfc7946#section-3.1.6
///
/// A LinearRing is a closed LineString with four or more positions.
/// The first and last positions are equivalent, and they MUST contain
/// identical values; their representation SHOULD also be identical.
pub struct Polygon {
  coordinates : Array[Array[@position.Position]]
  bbox : @bbox.BBox?
} derive(Show, Eq, Compare, Hash)

///|
pub fn Polygon::new(
  coordinates : Array[Array[@position.Position]],
  bbox? : @bbox.BBox? = None,
) -> Polygon raise InvalidPolygonError {
  for ring in coordinates {
    check_linear_ring(ring)
  }
  Polygon::{ coordinates, bbox }
}

///|
pub impl @primary.ToGeoJSONObject for Polygon with to_geojson_object(self) {
  @primary.GeoJSONObject::new(
    @primary.GeoJSONTypes::geometry(@primary.GeoJSONGeometryTypes::polygon()),
    bbox=self.bbox,
  )
}

///|
pub impl ToGeometry for Polygon with to_geometry(self) {
  Geometry::Polygon(self)
}

///|
pub impl ToJson for Polygon with to_json(self) {
  let base = self.to_geojson_object().to_json_map()
  base.set("coordinates", self.coordinates.to_json())
  base.to_json()
}

///|
pub impl FromJson for Polygon with from_json(json : Json, path : @json.JsonPath) {
  Polygon::new(
    @json.from_json(@helper.get_coordinates_field(json, path), path~),
    bbox=@primary.GeoJSONObject::from_json(json, path).bbox,
  ) catch {
    InvalidPolygonError(msg) =>
      raise @json.JsonDecodeError((path, "Invalid Polygon: \{msg}"))
    _ => raise @json.JsonDecodeError((path, "Invalid Polygon"))
  }
}
