// Benchmarks for simplify.mbt.

///|
test "bench: simplify_line_string RDP eps=0.5" (b : @bench.T) {
  let ls = @type.LineString::LineString(make_circle_coords(100, 5.0))
  b.bench(fn() { b.keep(simplify_line_string(ls, 0.5)) })
}
