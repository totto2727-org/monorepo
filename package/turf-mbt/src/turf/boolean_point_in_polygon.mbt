///|
fn in_bbox(
  px : Double,
  py : Double,
  west : Double,
  south : Double,
  east : Double,
  north : Double,
) -> Bool {
  west <= px && south <= py && east >= px && north >= py
}

///|
fn position_to_tuple(pos : @geojson.Position) -> (Double, Double) {
  match pos {
    @geojson.Position::Position2D(x, y) => (x, y)
    @geojson.Position::Position3D(x, y, _) => (x, y)
  }
}

///|
fn positions_to_tuples(
  positions : Array[@geojson.Position],
) -> Array[(Double, Double)] {
  positions.map(position_to_tuple)
}

///|
fn polygon_coords_to_rings(
  coords : Array[Array[@geojson.Position]],
) -> Array[Array[(Double, Double)]] {
  coords.map(positions_to_tuples)
}

///|
pub fn boolean_point_in_polygon(
  point : @geojson.Position,
  polygon : @geojson.Geometry,
  ignore_boundary? : Bool = false,
) -> Bool raise {
  let (px, py) = position_to_tuple(point)
  match polygon.get_bbox() {
    Some(bbox) => {
      let (west, south, east, north) = match bbox {
        @geojson.BBox::BBox2D(west, south, east, north) =>
          (west, south, east, north)
        @geojson.BBox::BBox3D(west, south, _, east, north, _) =>
          (west, south, east, north)
      }
      if not(in_bbox(px, py, west, south, east, north)) {
        return false
      }
    }
    None => ()
  }
  let polys : Array[Array[Array[(Double, Double)]]] = match polygon {
    @geojson.Geometry::Polygon(coordinates~, ..) =>
      [polygon_coords_to_rings(coordinates)]
    @geojson.Geometry::MultiPolygon(coordinates~, ..) =>
      coordinates.map(polygon_coords_to_rings)
    _ => fail("polygon must be a Polygon or MultiPolygon geometry")
  }
  let mut result = false
  for i = 0; i < polys.length(); i = i + 1 {
    let poly = polys[i]
    let poly_result = @point_in_polygon.point_in_polygon(px, py, poly)
    match poly_result {
      @point_in_polygon.PointInPolygonResult::Boundary =>
        if ignore_boundary {
          return false
        } else {
          return true
        }
      @point_in_polygon.PointInPolygonResult::Inside => result = true
      @point_in_polygon.PointInPolygonResult::Outside => ()
    }
  }
  result
}
