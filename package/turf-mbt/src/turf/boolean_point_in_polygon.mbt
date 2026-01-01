///|
fn in_bbox(point : @geojson.Position2D, bbox : @geojson.BBox2D) -> Bool {
  bbox.min.x <= point.x &&
  bbox.min.y <= point.y &&
  bbox.max.x >= point.x &&
  bbox.max.y >= point.y
}

///|
pub fn boolean_point_in_polygon(
  point : @geojson.Point,
  geometry : @geojson.Geometry,
  ignore_boundary? : Bool = false,
) -> Bool raise {
  let point_coordinate = point.coordinates.to_2d()
  let bbox = geometry.to_bbox().to_2d()
  if not(in_bbox(point_coordinate, bbox)) {
    return false
  }
  let polygon_array = match geometry {
    @geojson.Geometry::Polygon(polygon) => [polygon]
    @geojson.Geometry::MultiPolygon(multi_polygon) => multi_polygon.polygons
    _ => fail("polygon must be a Polygon or MultiPolygon geometry")
  }
  let mut result = false
  for polygon in polygon_array {
    let poly_result = @point_in_polygon.point_in_polygon(
      point_coordinate, polygon,
    )
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
