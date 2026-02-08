///|
pub(open) trait BBoxTrait {
  bbox(Self) -> BBox raise InvalidGeoJSONError
}

///|
pub(all) enum BBox {
  BBox2D(Double, Double, Double, Double)
  BBox3D(Double, Double, Double, Double, Double, Double)
} derive(Eq, Show)

///|
pub impl ToJson for BBox with to_json(self) {
  match self {
    BBox2D(x1, y1, x2, y2) => [x1, y1, x2, y2]
    BBox3D(x1, y1, z1, x2, y2, z2) => [x1, y1, z1, x2, y2, z2]
  }
}

///|
pub impl FromJson for BBox with from_json(json, path) {
  match json {
    Json::Array(
      [
        Json::Number(x1, ..),
        Json::Number(y1, ..),
        Json::Number(x2, ..),
        Json::Number(y2, ..),
      ]
    ) => BBox::BBox2D(x1, y1, x2, y2)
    Json::Array(
      [
        Json::Number(x1, ..),
        Json::Number(y1, ..),
        Json::Number(z1, ..),
        Json::Number(x2, ..),
        Json::Number(y2, ..),
        Json::Number(z2, ..),
      ]
    ) => BBox::BBox3D(x1, y1, z1, x2, y2, z2)
    _ => raise geojson_decode_error(path, "Invalid BBox", json)
  }
}

///|
pub fn BBox::new_2d(
  min_x : Double,
  min_y : Double,
  max_x : Double,
  max_y : Double,
) -> BBox {
  let x1 = @cmp.minimum(min_x, max_x)
  let y1 = @cmp.minimum(min_y, max_y)
  let x2 = @cmp.maximum(min_x, max_x)
  let y2 = @cmp.maximum(min_y, max_y)
  BBox2D(x1, y1, x2, y2)
}

///|
pub fn BBox::new_3d(
  min_x : Double,
  min_y : Double,
  min_z : Double,
  max_x : Double,
  max_y : Double,
  max_z : Double,
) -> BBox {
  let x1 = @cmp.minimum(min_x, max_x)
  let y1 = @cmp.minimum(min_y, max_y)
  let z1 = @cmp.minimum(min_z, max_z)
  let x2 = @cmp.maximum(min_x, max_x)
  let y2 = @cmp.maximum(min_y, max_y)
  let z2 = @cmp.maximum(min_z, max_z)
  BBox3D(x1, y1, z1, x2, y2, z2)
}

///|
pub fn BBox::from_coordinate_array(
  coords : Array[Coordinates],
) -> BBox raise InvalidGeoJSONError {
  if coords.length() == 0 {
    raise InvalidGeoJSONError("Coordinates array is empty")
  }
  let dim = coords[0].dimension()
  for i = 1; i < coords.length(); i = i + 1 {
    if coords[i].dimension() != dim {
      raise InvalidGeoJSONError("Coordinates must have the same dimension")
    }
  }
  match dim {
    2 => {
      // すでに長さの検証を行っているため、unwrapは安全
      let min_x = coords.iter().map(_.x()).minimum().unwrap()
      let max_x = coords.iter().map(_.x()).maximum().unwrap()
      let min_y = coords.iter().map(_.y()).minimum().unwrap()
      let max_y = coords.iter().map(_.y()).maximum().unwrap()
      BBox2D(min_x, min_y, max_x, max_y)
    }
    _ => {
      let min_x = coords.iter().map(_.x()).minimum().unwrap()
      let max_x = coords.iter().map(_.x()).maximum().unwrap()
      let min_y = coords.iter().map(_.y()).minimum().unwrap()
      let max_y = coords.iter().map(_.y()).maximum().unwrap()
      let min_z = coords
        .iter()
        // 3次元であることを保証しているため、unwrapは安全
        .map(coords => try! coords.z())
        .minimum()
        .unwrap()
      let max_z = coords
        .iter()
        // 3次元であることを保証しているため、unwrapは安全
        .map(coords => try! coords.z())
        .maximum()
        .unwrap()
      BBox3D(min_x, min_y, min_z, max_x, max_y, max_z)
    }
  }
}
