// Benchmarks for contains.mbt. Uses the public `Contains` trait surface so
// the bench tracks user-facing performance.

///|
test "bench: Contains for Polygon n=100" (b : @bench.T) {
  let exterior = @type.LineString::LineString(make_circle_coords(100, 5.0))
  let polygon = @type.Polygon::Polygon(exterior, [])
  let target = @type.Geometry::Point(@type.Point::Point(0.0, 0.0))
  b.bench(fn() { b.keep(Contains::contains(polygon, target)) })
}
