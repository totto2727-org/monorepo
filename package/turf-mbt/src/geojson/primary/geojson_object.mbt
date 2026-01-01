///|
/// The base GeoJSON object.
/// https://tools.ietf.org/html/rfc7946#section-3
/// The GeoJSON specification also allows foreign members
/// (https://tools.ietf.org/html/rfc7946#section-6.1)
pub struct GeoJSONObject {
  /// Specifies the type of GeoJSON object.
  _type : GeoJSONTypes
  /// Bounding box of the coordinate range of the object's Geometries, Features, or Feature Collections.
  /// The value of the bbox member is an array of length 2*n where n is the number of dimensions
  /// represented in the contained geometries, with all axes of the most southwesterly point
  /// followed by all axes of the more northeasterly point.
  /// The axes order of a bbox follows the axes order of geometries.
  /// https://tools.ietf.org/html/rfc7946#section-5
  bbox : @bbox.BBox?
} derive(Show, Eq, Compare, Hash)

///|
pub fn GeoJSONObject::new(
  _type : GeoJSONTypes,
  bbox? : @bbox.BBox? = None,
) -> GeoJSONObject {
  GeoJSONObject::{ _type, bbox }
}

///|
pub(open) trait ToGeoJSONObject {
  to_geojson_object(Self) -> GeoJSONObject
}

///|
pub fn GeoJSONObject::to_json_map(self : Self) -> Map[String, Json] {
  match self.bbox {
    None => { "type": self._type.to_json() }
    Some(bbox) => { "type": self._type.to_json(), "bbox": bbox.to_json() }
  }
}

///|
pub impl ToJson for GeoJSONObject with to_json(self) {
  self.to_json_map().to_json()
}

///|
pub impl FromJson for GeoJSONObject with from_json(self, path) {
  let _type : GeoJSONTypes = match @helper.get_field(self, "type") {
    Some(_type) => GeoJSONTypes::from_json(_type, path)
    _ => raise @json.JsonDecodeError((path, "Invalid GeoJSONObject"))
  }
  let bbox : @bbox.BBox? = match @helper.get_field(self, "bbox") {
    Some(bbox) => Some(@bbox.BBox::from_json(bbox, path))
    _ => None
  }
  GeoJSONObject::new(_type, bbox~)
}
