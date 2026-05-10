// Benchmarks for orient2d.mbt.

///|
test "bench: orient2d (robust)" (b : @bench.T) {
  let p = @type.Coord(0.0, 0.0)
  let q = @type.Coord(1.0, 0.0)
  let r = @type.Coord(0.0, 1.0)
  b.bench(fn() { b.keep(@robust.orient2d(p, q, r)) })
}
