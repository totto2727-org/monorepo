// Benchmarks for geo-mbt 2D algorithms, using MoonBit's built-in @bench.T
// framework. Run with `moon bench` from inside this package.
//
// These benchmarks exercise representative inputs of moderate size:
//
// - 100-coord LineString for iteration / length / simplify
// - 100-coord Polygon for area / centroid / bounding rect / contains
// - 50-point convex hull
// - 100-segment line intersection
// - 1000-entry R-tree (in the rtree package)

///|
fn make_circle_coords(n : Int, radius : Double) -> Array[@type.Coord] {
  let coords : Array[@type.Coord] = []
  for i = 0; i < n; i = i + 1 {
    let theta = i.to_double() / n.to_double() * 2.0 * 3.14159265358979323846
    coords.push(@type.Coord::new(radius * @math.cos(theta), radius * @math.sin(theta)))
  }
  // Close the ring
  if coords.length() > 0 {
    coords.push(coords[0])
  }
  coords
}

///|
test "bench: bounding_rect_of_line_string n=100" (b : @bench.T) {
  let ls = @type.LineString::new(make_circle_coords(100, 5.0))
  b.bench(fn() { b.keep(bounding_rect_of_line_string(ls)) })
}

///|
test "bench: signed_area_of_polygon n=100" (b : @bench.T) {
  let exterior = @type.LineString::new(make_circle_coords(100, 5.0))
  let polygon = @type.Polygon::new(exterior, [])
  b.bench(fn() { b.keep(signed_area_of_polygon(polygon)) })
}

///|
test "bench: centroid_polygon n=100" (b : @bench.T) {
  let exterior = @type.LineString::new(make_circle_coords(100, 5.0))
  let polygon = @type.Polygon::new(exterior, [])
  b.bench(fn() { b.keep(centroid_polygon(polygon)) })
}

///|
test "bench: euclidean_length_line_string n=100" (b : @bench.T) {
  let ls = @type.LineString::new(make_circle_coords(100, 5.0))
  b.bench(fn() { b.keep(euclidean_length_line_string(ls)) })
}

///|
test "bench: contains_polygon_coord n=100" (b : @bench.T) {
  let exterior = @type.LineString::new(make_circle_coords(100, 5.0))
  let polygon = @type.Polygon::new(exterior, [])
  let target = @type.Coord::new(0.0, 0.0)
  b.bench(fn() { b.keep(contains_polygon_coord(polygon, target)) })
}

///|
test "bench: convex_hull n=50" (b : @bench.T) {
  // Random-looking but deterministic coords
  let mp = @type.MultiPoint::from_tuples([
    (1.0, 2.0), (3.5, -1.2), (5.0, 5.0), (-1.0, 2.0), (10.0, 10.0),
    (-5.0, -5.0), (8.0, 2.0), (3.0, 8.0), (4.5, 3.5), (-2.0, 7.0),
    (6.0, -3.0), (9.0, 1.5), (2.0, -4.5), (7.5, 8.5), (0.5, 9.5),
    (1.5, 1.5), (4.0, 4.0), (-3.0, -1.0), (8.0, -2.0), (5.5, 6.5),
    (1.0, -3.0), (3.5, 7.5), (-1.5, 5.5), (10.5, 5.0), (4.0, -1.5),
    (-4.0, 3.0), (6.5, 4.5), (2.5, 9.0), (8.5, 7.0), (0.0, -4.0),
    (-2.5, -3.5), (5.5, 1.0), (3.0, 3.0), (7.0, 7.0), (1.0, 5.0),
    (9.5, 3.5), (-3.5, 6.5), (4.5, 9.5), (6.0, 0.5), (2.0, 2.5),
    (-1.0, -2.0), (8.5, 4.5), (3.5, 5.5), (-4.5, 1.5), (5.0, -3.5),
    (7.5, 2.5), (0.5, 6.0), (-2.0, 4.5), (4.0, 8.0), (10.0, 0.0),
  ])
  b.bench(fn() { b.keep(convex_hull_of_multi_point(mp)) })
}

///|
test "bench: simplify_line_string RDP eps=0.5" (b : @bench.T) {
  let ls = @type.LineString::new(make_circle_coords(100, 5.0))
  b.bench(fn() { b.keep(simplify_line_string(ls, 0.5)) })
}

///|
test "bench: line_intersection crossing" (b : @bench.T) {
  let l1 = @type.Line::from_tuples((0.0, 0.0), (10.0, 10.0))
  let l2 = @type.Line::from_tuples((0.0, 10.0), (10.0, 0.0))
  b.bench(fn() { b.keep(line_intersection(l1, l2)) })
}

///|
test "bench: orient2d (robust)" (b : @bench.T) {
  let p = @type.Coord::new(0.0, 0.0)
  let q = @type.Coord::new(1.0, 0.0)
  let r = @type.Coord::new(0.0, 1.0)
  b.bench(fn() { b.keep(@robust.orient2d(p, q, r)) })
}

///|
test "bench: frechet_distance n=20 vs n=20" (b : @bench.T) {
  let a = @type.LineString::new(make_circle_coords(20, 5.0))
  let b_ls = @type.LineString::new(make_circle_coords(20, 6.0))
  b.bench(fn() { b.keep(frechet_distance(a, b_ls)) })
}

///|
test "bench: hausdorff_distance n=50 vs n=50" (b : @bench.T) {
  let a_coords = make_circle_coords(50, 5.0)
  let b_coords = make_circle_coords(50, 6.0)
  b.bench(fn() { b.keep(hausdorff_distance_coords(a_coords, b_coords)) })
}

///|
test "bench: coords_of_polygon n=100" (b : @bench.T) {
  let exterior = @type.LineString::new(make_circle_coords(100, 5.0))
  let polygon = @type.Polygon::new(exterior, [])
  b.bench(fn() { b.keep(coords_of_polygon(polygon)) })
}

///|
test "bench: affine transform translate+rotate compose" (b : @bench.T) {
  let t = AffineTransform::translate_xy(10.0, 5.0)
  let r = AffineTransform::rotate_origin(45.0)
  b.bench(fn() { b.keep(t.compose(r)) })
}

///|
test "bench: chaikin_smoothing 3 iterations" (b : @bench.T) {
  let ls = @type.LineString::new(make_circle_coords(50, 5.0))
  b.bench(fn() { b.keep(chaikin_smoothing(ls, 3)) })
}
