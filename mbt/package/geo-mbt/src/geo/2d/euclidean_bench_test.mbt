// Benchmarks for euclidean.mbt.

///|
test "bench: euclidean_length_line_string n=100" (b : @bench.T) {
  let ls = @type.LineString::LineString(make_circle_coords(100, 5.0))
  b.bench(fn() { b.keep(euclidean_length_line_string(ls)) })
}
