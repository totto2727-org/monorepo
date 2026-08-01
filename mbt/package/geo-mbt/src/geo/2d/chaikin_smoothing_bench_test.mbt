// Benchmarks for chaikin_smoothing.mbt.

///|
test "bench: chaikin_smoothing 3 iterations" (b : @bench.T) {
  let ls = @type.LineString::LineString(make_circle_coords(50, 5.0))
  b.bench(fn() { b.keep(chaikin_smoothing(ls, 3)) })
}
