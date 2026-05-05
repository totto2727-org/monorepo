// Tests for the R-tree spatial index.

///|
fn make_unit_rect(x : Double, y : Double) -> @type.Rect {
  @type.Rect::new(
    @type.Coord::new(x, y),
    @type.Coord::new(x + 1.0, y + 1.0),
  )
}

///|
test "empty RTree" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::bulk_load([])
  assert_true(tree.is_empty())
  assert_eq(tree.size(), 0)
  assert_true(
    tree.query_rect_intersection(
      @type.Rect::new(@type.Coord::new(0.0, 0.0), @type.Coord::new(10.0, 10.0)),
    ).length() == 0,
  )
}

///|
test "single entry intersection" {
  let entries = [@rtree.Entry::new(make_unit_rect(0.0, 0.0), 1)]
  let tree = @rtree.RTree::bulk_load(entries)
  assert_eq(tree.size(), 1)
  let hits = tree.query_rect_intersection(
    @type.Rect::new(@type.Coord::new(0.5, 0.5), @type.Coord::new(2.0, 2.0)),
  )
  assert_eq(hits.length(), 1)
  assert_eq(hits[0], 1)
}

///|
test "many entries: rectangular query" {
  let entries : Array[@rtree.Entry[Int]] = []
  for x = 0; x < 10; x = x + 1 {
    for y = 0; y < 10; y = y + 1 {
      entries.push(
        @rtree.Entry::new(make_unit_rect(x.to_double(), y.to_double()), x * 10 + y),
      )
    }
  }
  let tree = @rtree.RTree::bulk_load(entries)
  assert_eq(tree.size(), 100)
  // Query a 3x3 region
  let hits = tree.query_rect_intersection(
    @type.Rect::new(@type.Coord::new(2.5, 2.5), @type.Coord::new(5.5, 5.5)),
  )
  // Should be at least 9 (the 3x3 grid in the middle), possibly more for
  // entries straddling the boundary.
  assert_true(hits.length() >= 9)
}

///|
test "query_nearest: empty returns None" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::bulk_load([])
  assert_true(tree.query_nearest(@type.Coord::new(0.0, 0.0)) == None)
}

///|
test "query_nearest: returns the nearest entry" {
  let entries = [
    @rtree.Entry::new(make_unit_rect(0.0, 0.0), 1),
    @rtree.Entry::new(make_unit_rect(10.0, 10.0), 2),
    @rtree.Entry::new(make_unit_rect(5.0, 5.0), 3),
  ]
  let tree = @rtree.RTree::bulk_load(entries)
  let nearest = tree.query_nearest(@type.Coord::new(0.5, 0.5)).unwrap()
  assert_eq(nearest, 1)
  let nearest_far = tree.query_nearest(@type.Coord::new(20.0, 20.0)).unwrap()
  assert_eq(nearest_far, 2)
}

///|
test "exhaustive verification: query against all entries" {
  let entries : Array[@rtree.Entry[Int]] = []
  let coords = [
    (0.0, 0.0),
    (3.5, 1.2),
    (5.0, 5.0),
    (-1.0, 2.0),
    (10.0, 10.0),
    (-5.0, -5.0),
    (8.0, 2.0),
    (3.0, 8.0),
  ]
  for i = 0; i < coords.length(); i = i + 1 {
    let (x, y) = coords[i]
    entries.push(@rtree.Entry::new(make_unit_rect(x, y), i))
  }
  let tree = @rtree.RTree::bulk_load(entries)
  let query = @type.Rect::new(
    @type.Coord::new(0.0, 0.0),
    @type.Coord::new(6.0, 6.0),
  )
  let hits = tree.query_rect_intersection(query)
  // Brute-force expected:
  let expected : Array[Int] = []
  for i = 0; i < coords.length(); i = i + 1 {
    let (x, y) = coords[i]
    let r = make_unit_rect(x, y)
    if !(
      r.max().x() < query.min().x() ||
      query.max().x() < r.min().x() ||
      r.max().y() < query.min().y() ||
      query.max().y() < r.min().y()
    ) {
      expected.push(i)
    }
  }
  // Sort both and compare lengths (ordering not guaranteed by the tree)
  hits.sort()
  expected.sort()
  assert_eq(hits.length(), expected.length())
  for i = 0; i < hits.length(); i = i + 1 {
    assert_eq(hits[i], expected[i])
  }
}
