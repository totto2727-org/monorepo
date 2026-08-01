// Benchmarks for centroid.mbt.

///|
test "bench: centroid_polygon n=100" (b : @bench.T) {
  let exterior = @type.LineString::LineString(make_circle_coords(100, 5.0))
  let polygon = @type.Polygon::Polygon(exterior, [])
  b.bench(fn() { b.keep(HasCentroid::centroid(polygon)) })
}
