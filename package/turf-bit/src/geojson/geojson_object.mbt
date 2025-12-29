///|
/// The base GeoJSON object.
/// https://tools.ietf.org/html/rfc7946#section-3
/// The GeoJSON specification also allows foreign members
/// (https://tools.ietf.org/html/rfc7946#section-6.1)
pub struct GeoJsonObject {
  /// Specifies the type of GeoJSON object.
  _type : GeoJsonTypes
  /// Bounding box of the coordinate range of the object's Geometries, Features, or Feature Collections.
  /// The value of the bbox member is an array of length 2*n where n is the number of dimensions
  /// represented in the contained geometries, with all axes of the most southwesterly point
  /// followed by all axes of the more northeasterly point.
  /// The axes order of a bbox follows the axes order of geometries.
  /// https://tools.ietf.org/html/rfc7946#section-5
  bbox : BBox?
} derive(Show, Eq, Compare, Hash)

///|
pub fn GeoJsonObject::new(
  _type : GeoJsonTypes,
  bbox? : BBox? = None,
) -> GeoJsonObject {
  GeoJsonObject::{ _type, bbox }
}

///|
pub impl ToJson for GeoJsonObject with to_json(self) {
  match self.bbox {
    None => { "type": self._type.to_json() }
    Some(bbox) => { "type": self._type.to_json(), "bbox": bbox.to_json() }
  }
}

///|
pub impl FromJson for GeoJsonObject with from_json(self, path) {
  let _type : GeoJsonTypes = match self {
    { "type": String(_) as _type, .. } =>
      (@json.from_json(_type, path~) : GeoJsonTypes)
    _ => raise @json.JsonDecodeError((path, "Invalid GeoJsonObject"))
  }
  let bbox : BBox? = match self {
    { "bbox": Array(_) as bbox, .. } =>
      Some((@json.from_json(bbox, path~) : BBox))
    _ => None
  }
  GeoJsonObject::new(_type, bbox~)
}

///|
pub trait ToGeoJsonObject {
  to_geojson_object(Self) -> GeoJsonObject
}
