// Benchmarks for coords_iter.mbt.

///|
test "bench: coords_of_polygon n=100" (b : @bench.T) {
  let exterior = @type.LineString::LineString(make_circle_coords(100, 5.0))
  let polygon = @type.Polygon::Polygon(exterior, [])
  b.bench(fn() { b.keep(CoordsCarrier::coords(polygon)) })
}
