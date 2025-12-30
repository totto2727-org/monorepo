///|
pub enum PointInPolygonResult {
  Inside
  Outside
  Boundary
} derive(Show, Eq)

///|
pub fn point_in_polygon(
  x : Double,
  y : Double,
  polygon : Array[Array[(Double, Double)]],
) -> PointInPolygonResult raise {
  let mut k = 0
  let num_contours = polygon.length()
  for i = 0; i < num_contours; i = i + 1 {
    let contour = polygon[i]
    let contour_len = contour.length() - 1
    if contour_len < 1 {
      continue
    }
    let (first_x, first_y) = contour[0]
    let (last_x, last_y) = contour[contour_len]
    if first_x != last_x || first_y != last_y {
      fail("First and last coordinates in a ring must be the same")
    }
    let mut current_x = first_x
    let mut current_y = first_y
    let mut u1 = current_x - x
    let mut v1 = current_y - y
    for ii = 0; ii < contour_len; ii = ii + 1 {
      let (next_x, next_y) = contour[ii + 1]
      let u2 = next_x - x
      let v2 = next_y - y
      if v1 == 0.0 && v2 == 0.0 {
        if (u2 <= 0.0 && u1 >= 0.0) || (u1 <= 0.0 && u2 >= 0.0) {
          return PointInPolygonResult::Boundary
        }
      } else if (v2 >= 0.0 && v1 <= 0.0) || (v2 <= 0.0 && v1 >= 0.0) {
        let f = @robust.orient2d(
          @geojson.Position::new2D(u1, v1),
          @geojson.Position::new2D(u2, v2),
          @geojson.Position::new2D(0.0, 0.0),
        )
        if f == 0.0 {
          return PointInPolygonResult::Boundary
        }
        if (f > 0.0 && v2 > 0.0 && v1 <= 0.0) ||
          (f < 0.0 && v2 <= 0.0 && v1 > 0.0) {
          k += 1
        }
      }
      current_x = next_x
      current_y = next_y
      v1 = v2
      u1 = u2
    }
  }
  if k % 2 == 0 {
    PointInPolygonResult::Outside
  } else {
    PointInPolygonResult::Inside
  }
}
