///|
/// MultiPoint geometry object.
/// https://tools.ietf.org/html/rfc7946#section-3.1.3
pub struct MultiPoint {
  points : Array[Point]
  bbox : @primary.BBox?
} derive(Show, Eq, Compare, Hash)

///|
pub fn MultiPoint::new(
  points : Array[Point],
  bbox? : @primary.BBox? = None,
) -> MultiPoint {
  MultiPoint::{ points, bbox }
}

///|
pub impl @primary.ToGeoJSONObject for MultiPoint with to_geojson_object(self) {
  @primary.GeoJSONObject::new(
    @primary.GeoJSONTypes::geometry(
      @primary.GeoJSONGeometryTypes::multi_point(),
    ),
    bbox=self.bbox,
  )
}

///|
pub impl ToGeometry for MultiPoint with to_geometry(self) {
  Geometry::MultiPoint(self)
}

///|
pub impl ToJson for MultiPoint with to_json(self) {
  let base = self.to_geojson_object().to_json_map()
  let coordinates = self.points |> Array::map(p => p.to_json())
  base.set("coordinates", coordinates.to_json())
  base.to_json()
}

///|
pub impl FromJson for MultiPoint with from_json(
  json : Json,
  path : @json.JsonPath,
) {
  let points = match @helper.get_coordinates_field(json, path) {
    Array(array) => array.map(json => Point::new(@json.from_json(json, path~)))
    _ =>
      raise @json.JsonDecodeError(
        (path, "Invalid coordinates in json: \{json}"),
      )
  }
  MultiPoint::new(
    points,
    bbox=@primary.GeoJSONObject::from_json(json, path).bbox,
  )
}
