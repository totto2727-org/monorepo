///|
/// MultiPolygon geometry object.
/// https://tools.ietf.org/html/rfc7946#section-3.1.7
pub struct MultiPolygon {
  polygons : Array[Polygon]
  bbox : BBox?
} derive(Show, Eq, Compare, Hash)

///|
pub fn MultiPolygon::new(
  polygons : Array[Polygon],
  bbox? : BBox? = None,
) -> MultiPolygon {
  MultiPolygon::{ polygons, bbox }
}

///|
pub impl ToGeoJSONObject for MultiPolygon with to_geojson_object(self) {
  GeoJSONObject::new(
    GeoJSONTypes::geometry(GeoJSONGeometryTypes::multi_polygon()),
    bbox=self.bbox,
  )
}

///|
pub impl GeometryToBBox for MultiPolygon with to_bbox(self, re_compute? = false) {
  match (self.bbox, re_compute) {
    (Some(bbox), false) => bbox
    _ => {
      let position_array = self.polygons
        .map(p => p.to_bbox().to_bbox_2d())
        .map(bbox => [bbox.min, bbox.max])
        .flatten()
      BBox2D::from_positions(position_array).to_bbox()
    }
  }
}

///|
pub impl ToGeometry for MultiPolygon with to_geometry(self) {
  Geometry::MultiPolygon(self)
}

///|
pub impl ToJson for MultiPolygon with to_json(self) {
  let base = self.to_geojson_object().to_json_map()
  let coordinates = self.polygons |> Array::map(p => p.coordinates.to_json())
  base.set("coordinates", coordinates.to_json())
  base.to_json()
}

///|
pub impl FromJson for MultiPolygon with from_json(
  json : Json,
  path : @json.JsonPath,
) {
  let polygons = match @helper.get_coordinates_field(json, path) {
    Array(array) =>
      array.map(json => Polygon::new(@json.from_json(json, path~))) catch {
        e =>
          raise @json.JsonDecodeError(
            (path, "Invalid coordinates in json: \{json}: \{e}"),
          )
      }
    _ =>
      raise @json.JsonDecodeError(
        (path, "Invalid coordinates in json: \{json}"),
      )
  }
  MultiPolygon::new(polygons, bbox=GeoJSONObject::from_json(json, path).bbox)
}
