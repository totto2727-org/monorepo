// Benchmarks for the R-tree spatial index.

///|
fn make_grid_entries(side : Int) -> Array[@rtree.Entry[Int]] {
  Array::makei(side * side, fn(idx) {
    let x = idx / side
    let y = idx % side
    let r = @type.Rect::Rect(
      @type.Coord(x.to_double(), y.to_double()),
      @type.Coord(x.to_double() + 1.0, y.to_double() + 1.0),
    )
    @rtree.Entry(r, x * side + y)
  })
}

///|
test "bench: RTree::bulk_load n=1000" (b : @bench.T) {
  let entries = make_grid_entries(32) // 1024 entries
  b.bench(fn() { b.keep(@rtree.RTree::bulk_load(entries)) })
}

///|
test "bench: RTree::query_rect_intersection n=1000 small query" (b : @bench.T) {
  let tree = @rtree.RTree::bulk_load(make_grid_entries(32))
  let q = @type.Rect::Rect(@type.Coord(5.0, 5.0), @type.Coord(10.0, 10.0))
  b.bench(fn() { b.keep(tree.query_rect_intersection(q)) })
}

///|
test "bench: RTree::query_rect_intersection n=1000 large query" (b : @bench.T) {
  let tree = @rtree.RTree::bulk_load(make_grid_entries(32))
  let q = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(32.0, 32.0))
  b.bench(fn() { b.keep(tree.query_rect_intersection(q)) })
}

///|
test "bench: RTree::query_nearest n=1000" (b : @bench.T) {
  let tree = @rtree.RTree::bulk_load(make_grid_entries(32))
  let target = @type.Coord(15.5, 15.5)
  b.bench(fn() { b.keep(tree.query_nearest(target)) })
}
