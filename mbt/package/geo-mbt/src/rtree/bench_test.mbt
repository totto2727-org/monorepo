// Benchmarks for the R-tree spatial index.

///|
fn make_grid_entries(side : Int) -> Array[@rtree.Entry[Int]] {
  let entries : Array[@rtree.Entry[Int]] = []
  for x = 0; x < side; x = x + 1 {
    for y = 0; y < side; y = y + 1 {
      let r = @type.Rect::new(
        @type.Coord::new(x.to_double(), y.to_double()),
        @type.Coord::new(x.to_double() + 1.0, y.to_double() + 1.0),
      )
      entries.push(@rtree.Entry::new(r, x * side + y))
    }
  }
  entries
}

///|
test "bench: RTree::bulk_load n=1000" (b : @bench.T) {
  let entries = make_grid_entries(32) // 1024 entries
  b.bench(fn() { b.keep(@rtree.RTree::bulk_load(entries)) })
}

///|
test "bench: RTree::query_rect_intersection n=1000 small query" (b : @bench.T) {
  let tree = @rtree.RTree::bulk_load(make_grid_entries(32))
  let q = @type.Rect::new(@type.Coord::new(5.0, 5.0), @type.Coord::new(10.0, 10.0))
  b.bench(fn() { b.keep(tree.query_rect_intersection(q)) })
}

///|
test "bench: RTree::query_rect_intersection n=1000 large query" (b : @bench.T) {
  let tree = @rtree.RTree::bulk_load(make_grid_entries(32))
  let q = @type.Rect::new(@type.Coord::new(0.0, 0.0), @type.Coord::new(32.0, 32.0))
  b.bench(fn() { b.keep(tree.query_rect_intersection(q)) })
}

///|
test "bench: RTree::query_nearest n=1000" (b : @bench.T) {
  let tree = @rtree.RTree::bulk_load(make_grid_entries(32))
  let target = @type.Coord::new(15.5, 15.5)
  b.bench(fn() { b.keep(tree.query_nearest(target)) })
}
