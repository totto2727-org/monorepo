///|
fn[Coord : @type.Coord2DTrait] in_bbox(
  point : Coord,
  bbox : @type.BBox[Coord],
) -> Bool {
  bbox.min.x() <= point.x() &&
  bbox.min.y() <= point.y() &&
  bbox.max.x() >= point.x() &&
  bbox.max.y() >= point.y()
}

///|
pub fn[Point : @type.PointTrait, Polygon : @type.PolygonTrait] boolean_point_in_polygon(
  point : Point,
  polygon : Polygon,
  ignore_boundary? : Bool = false,
) -> Bool raise {
  let coord = point.coord()
  let bbox = polygon.bbox()
  if not(in_bbox(coord, bbox)) {
    return false
  }
  match @point_in_ring.point_in_ring(coord, polygon.exterior()) {
    @point_in_ring.PointInRingResult::Boundary => !ignore_boundary
    @point_in_ring.PointInRingResult::Inside => {
      for ring in polygon.interior_array() {
        let result = @point_in_ring.point_in_ring(coord, ring)
        match result {
          @point_in_ring.PointInRingResult::Boundary => return !ignore_boundary
          @point_in_ring.PointInRingResult::Inside => return false
          @point_in_ring.PointInRingResult::Outside => ()
        }
      }
      return true
    }
    @point_in_ring.PointInRingResult::Outside => return false
  }
}
