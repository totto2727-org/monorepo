// Benchmarks for hausdorff_distance.mbt.

///|
test "bench: hausdorff_distance n=50 vs n=50" (b : @bench.T) {
  let a_coords = make_circle_coords(50, 5.0)
  let b_coords = make_circle_coords(50, 6.0)
  b.bench(fn() { b.keep(hausdorff_distance_coords(a_coords, b_coords)) })
}
