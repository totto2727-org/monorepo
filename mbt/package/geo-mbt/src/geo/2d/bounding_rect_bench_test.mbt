// Benchmarks for bounding_rect.mbt.

///|
fn make_circle_coords(n : Int, radius : Double) -> Array[@type.Coord] {
  if n <= 0 {
    return []
  }
  let circle = Array::makei(n, fn(i) {
    let theta = i.to_double() / n.to_double() * 2.0 * 3.14159265358979323846
    @type.Coord(radius * @math.cos(theta), radius * @math.sin(theta))
  })
  [..circle, circle[0]]
}

///|
test "bench: bounding_rect_of_line_string n=100" (b : @bench.T) {
  let ls = @type.LineString::LineString(make_circle_coords(100, 5.0))
  b.bench(fn() { b.keep(Bounded::bbox(ls)) })
}
