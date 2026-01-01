///|
fn in_bbox(point : @geojson.Position2D, bbox : @geojson.BBox2D) -> Bool {
  let (x, y) = point
  let (west, south, east, north) = bbox
  west <= x && south <= y && east >= x && north >= y
}

///|
fn positions_to_position_2d_array(
  positions : Array[@geojson.Position],
) -> Array[@geojson.Position2D] {
  positions.map(@geojson.Position::to_2d)
}

///|
fn polygon_coords_to_rings(
  coords : Array[Array[@geojson.Position]],
) -> Array[Array[(Double, Double)]] {
  coords.map(positions_to_position_2d_array)
}

///|
pub fn boolean_point_in_polygon(
  point : @geojson.Point,
  polygon : @geojson.Polygon,
  ignore_boundary? : Bool = false,
) -> Bool raise {
  let point_coordinates = point.coordinates.to_2d()
  match polygon.get_bbox() {
    Some(bbox) => {
      let (west, south, east, north) = match bbox {
        @geojson.BBox::BBox2D(west, south, east, north) =>
          (west, south, east, north)
      }
      if not(
          in_bbox(
            point_coordinates.0,
            point_coordinates.1,
            west,
            south,
            east,
            north,
          ),
        ) {
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
