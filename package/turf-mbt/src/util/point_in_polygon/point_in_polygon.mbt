///|
pub enum PointInPolygonResult {
  Inside
  Outside
  Boundary
} derive(Show, Eq)

///|
pub fn point_in_polygon(
  position : @geojson.Position2D,
  polygon : @geojson.Polygon,
) -> PointInPolygonResult raise {
  let mut k = 0
  for coordinates in polygon.coordinates {
    let contour = coordinates
    let contour_len = contour.length() - 1
    if contour_len < 1 {
      continue
    }
    let first = contour[0].to_2d()
    let last = contour[contour_len].to_2d()
    if first.x != last.x || first.y != last.y {
      fail("First and last coordinates in a ring must be the same")
    }
    let mut current = first
    let mut diff1 = @geojson.Position2D::new(
      (current.x - position.x, current.y - position.y),
    )
    for ii = 0; ii < contour_len; ii = ii + 1 {
      let next = contour[ii + 1].to_2d()
      let diff2 = @geojson.Position2D::new(
        (next.x - position.x, next.y - position.y),
      )
      if diff1.y == 0.0 && diff2.y == 0.0 {
        if (diff2.x <= 0.0 && diff1.x >= 0.0) ||
          (diff1.x <= 0.0 && diff2.x >= 0.0) {
          return PointInPolygonResult::Boundary
        }
      } else if (diff2.y >= 0.0 && diff1.y <= 0.0) ||
        (diff2.y <= 0.0 && diff1.y >= 0.0) {
        let f = @robust.orient2d(
          diff1,
          diff2,
          @geojson.Position2D::new((0.0, 0.0)),
        )
        if f == 0.0 {
          return PointInPolygonResult::Boundary
        }
        if (f > 0.0 && diff2.y > 0.0 && diff1.y <= 0.0) ||
          (f < 0.0 && diff2.y <= 0.0 && diff1.y > 0.0) {
          k += 1
        }
      }
      current = next
      diff1 = diff2
    }
  }
  if k % 2 == 0 {
    PointInPolygonResult::Outside
  } else {
    PointInPolygonResult::Inside
  }
}
