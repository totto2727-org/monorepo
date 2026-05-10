// Benchmarks for frechet_distance.mbt.

///|
test "bench: frechet_distance n=20 vs n=20" (b : @bench.T) {
  let a = @type.LineString::LineString(make_circle_coords(20, 5.0))
  let b_ls = @type.LineString::LineString(make_circle_coords(20, 6.0))
  b.bench(fn() { b.keep(frechet_distance(a, b_ls)) })
}
