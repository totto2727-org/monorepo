// Benchmarks for affine_transform.mbt.

///|
test "bench: affine transform translate+rotate compose" (b : @bench.T) {
  let t = AffineTransform::translate_xy(10.0, 5.0)
  let r = AffineTransform::rotate_origin(45.0)
  b.bench(fn() { b.keep(t.compose(r)) })
}
