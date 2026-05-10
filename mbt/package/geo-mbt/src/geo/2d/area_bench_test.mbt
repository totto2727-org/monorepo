// Benchmarks for area.mbt.

///|
test "bench: signed_area_of_polygon n=100" (b : @bench.T) {
  let exterior = @type.LineString::LineString(make_circle_coords(100, 5.0))
  let polygon = @type.Polygon::Polygon(exterior, [])
  b.bench(fn() { b.keep(HasArea::signed_area(polygon)) })
}
