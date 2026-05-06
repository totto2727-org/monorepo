// Tests for the R-tree spatial index.

///|
fn make_unit_rect(x : Double, y : Double) -> @type.Rect {
  @type.Rect::Rect(@type.Coord(x, y), @type.Coord(x + 1.0, y + 1.0))
}

///|
test "empty RTree" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::bulk_load([])
  assert_true(tree.is_empty())
  assert_eq(tree.size(), 0)
  assert_true(
    tree
    .query_rect_intersection(
      @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(10.0, 10.0)),
    )
    .length() ==
    0,
  )
}

///|
test "single entry intersection" {
  let entries = [@rtree.Entry(make_unit_rect(0.0, 0.0), 1)]
  let tree = @rtree.RTree::bulk_load(entries)
  assert_eq(tree.size(), 1)
  let hits = tree.query_rect_intersection(
    @type.Rect::Rect(@type.Coord(0.5, 0.5), @type.Coord(2.0, 2.0)),
  )
  assert_eq(hits.length(), 1)
  assert_eq(hits[0], 1)
}

///|
test "many entries: rectangular query" {
  let entries = Array::makei(100, fn(idx) {
    let x = idx / 10
    let y = idx % 10
    @rtree.Entry(make_unit_rect(x.to_double(), y.to_double()), x * 10 + y)
  })
  let tree = @rtree.RTree::bulk_load(entries)
  assert_eq(tree.size(), 100)
  // Query a 3x3 region
  let hits = tree.query_rect_intersection(
    @type.Rect::Rect(@type.Coord(2.5, 2.5), @type.Coord(5.5, 5.5)),
  )
  // Should be at least 9 (the 3x3 grid in the middle), possibly more for
  // entries straddling the boundary.
  assert_true(hits.length() >= 9)
}

///|
test "query_nearest: empty returns None" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::bulk_load([])
  assert_true(tree.query_nearest(@type.Coord(0.0, 0.0)) == None)
}

///|
test "query_nearest: returns the nearest entry" {
  let entries = [
    @rtree.Entry(make_unit_rect(0.0, 0.0), 1),
    @rtree.Entry(make_unit_rect(10.0, 10.0), 2),
    @rtree.Entry(make_unit_rect(5.0, 5.0), 3),
  ]
  let tree = @rtree.RTree::bulk_load(entries)
  let nearest = tree.query_nearest(@type.Coord(0.5, 0.5)).unwrap()
  assert_eq(nearest, 1)
  let nearest_far = tree.query_nearest(@type.Coord(20.0, 20.0)).unwrap()
  assert_eq(nearest_far, 2)
}

///|
test "exhaustive verification: query against all entries" {
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
  let entries = Array::makei(coords.length(), fn(i) {
    let (x, y) = coords[i]
    @rtree.Entry(make_unit_rect(x, y), i)
  })
  let tree = @rtree.RTree::bulk_load(entries)
  let query = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(6.0, 6.0))
  let hits = tree.query_rect_intersection(query)
  // Brute-force expected via index filter.
  let expected = (0)
    .until(coords.length())
    .filter(fn(i) {
      let (x, y) = coords[i]
      let r = make_unit_rect(x, y)
      !(r.max().x() < query.min().x() ||
      query.max().x() < r.min().x() ||
      r.max().y() < query.min().y() ||
      query.max().y() < r.min().y())
    })
    .collect()
  // Sort both and compare (ordering not guaranteed by the tree).
  hits.sort()
  expected.sort()
  assert_eq(hits.length(), expected.length())
  for i, hit in hits {
    assert_eq(hit, expected[i])
  }
}
