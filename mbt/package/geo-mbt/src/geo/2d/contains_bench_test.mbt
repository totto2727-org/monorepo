// Benchmarks for contains.mbt.

///|
test "bench: contains_polygon_coord n=100" (b : @bench.T) {
  let exterior = @type.LineString::LineString(make_circle_coords(100, 5.0))
  let polygon = @type.Polygon::Polygon(exterior, [])
  let target = @type.Coord(0.0, 0.0)
  b.bench(fn() { b.keep(contains_polygon_coord(polygon, target)) })
}
