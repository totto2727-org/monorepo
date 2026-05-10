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
test "RTree::new: empty tree" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::new()
  assert_true(tree.is_empty())
  assert_eq(tree.size(), 0)
}

///|
test "insert: size increments per item" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::new()
  tree.insert(@rtree.Entry(make_unit_rect(0.0, 0.0), 1))
  assert_eq(tree.size(), 1)
  tree.insert(@rtree.Entry(make_unit_rect(1.0, 1.0), 2))
  assert_eq(tree.size(), 2)
}

///|
test "insert N items, iter yields N" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::new()
  for i in 0..<50 {
    tree.insert(@rtree.Entry(make_unit_rect(i.to_double(), i.to_double()), i))
  }
  assert_eq(tree.size(), 50)
  assert_eq(tree.iter().count(), 50)
}

///|
test "insert with splits keeps query results correct" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::new()
  // 100 items forces multiple node splits and tree growth (MAX_ENTRIES=16).
  for i in 0..<100 {
    let x = (i / 10).to_double()
    let y = (i % 10).to_double()
    tree.insert(@rtree.Entry(make_unit_rect(x, y), i))
  }
  assert_eq(tree.size(), 100)
  let hits = tree.query_rect_intersection(
    @type.Rect::Rect(@type.Coord(2.5, 2.5), @type.Coord(5.5, 5.5)),
  )
  assert_true(hits.length() >= 9)
}

///|
test "remove existing returns Some, size decrements" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::new()
  for i in 0..<5 {
    tree.insert(@rtree.Entry(make_unit_rect(i.to_double(), 0.0), i))
  }
  let removed = tree.remove(@rtree.Entry(make_unit_rect(2.0, 0.0), 2))
  assert_true(removed == Some(2))
  assert_eq(tree.size(), 4)
}

///|
test "remove non-existent returns None, size unchanged" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::new()
  for i in 0..<5 {
    tree.insert(@rtree.Entry(make_unit_rect(i.to_double(), 0.0), i))
  }
  let removed = tree.remove(@rtree.Entry(make_unit_rect(99.0, 99.0), 99))
  assert_true(removed == None)
  assert_eq(tree.size(), 5)
}

///|
test "remove all leaves empty tree" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::new()
  for i in 0..<5 {
    tree.insert(@rtree.Entry(make_unit_rect(i.to_double(), 0.0), i))
  }
  for i in 0..<5 {
    let _ = tree.remove(@rtree.Entry(make_unit_rect(i.to_double(), 0.0), i))
  }
  assert_true(tree.is_empty())
  assert_eq(tree.size(), 0)
}

///|
test "locate_at_point: finds overlapping rects" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::new()
  tree.insert(
    @rtree.Entry(
      @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(5.0, 5.0)),
      0,
    ),
  )
  tree.insert(
    @rtree.Entry(
      @type.Rect::Rect(@type.Coord(2.0, 2.0), @type.Coord(3.0, 3.0)),
      1,
    ),
  )
  tree.insert(
    @rtree.Entry(
      @type.Rect::Rect(@type.Coord(2.5, 2.5), @type.Coord(10.0, 10.0)),
      2,
    ),
  )
  tree.insert(
    @rtree.Entry(
      @type.Rect::Rect(@type.Coord(20.0, 20.0), @type.Coord(30.0, 30.0)),
      3,
    ),
  )
  let hits = tree.locate_at_point(@type.Coord(2.5, 2.5))
  hits.sort()
  assert_eq(hits, [0, 1, 2])
}

///|
test "locate_within_distance: finds entries within radius" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::new()
  // bbox dist² from (0,0): 0, 1, 4, 25, 100
  tree.insert(@rtree.Entry(make_unit_rect(0.0, 0.0), 0))
  tree.insert(@rtree.Entry(make_unit_rect(1.0, 0.0), 1))
  tree.insert(@rtree.Entry(make_unit_rect(2.0, 0.0), 2))
  tree.insert(@rtree.Entry(make_unit_rect(5.0, 0.0), 3))
  tree.insert(@rtree.Entry(make_unit_rect(10.0, 0.0), 4))
  let hits = tree.locate_within_distance(@type.Coord(0.0, 0.0), 2.5)
  hits.sort()
  assert_eq(hits, [0, 1, 2])
}

///|
test "nearest_neighbors: returns elements in distance order" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::new()
  tree.insert(@rtree.Entry(make_unit_rect(5.0, 5.0), 0))
  tree.insert(@rtree.Entry(make_unit_rect(0.0, 0.0), 1))
  tree.insert(@rtree.Entry(make_unit_rect(3.0, 3.0), 2))
  let nn = tree.nearest_neighbors(@type.Coord(0.0, 0.0), None)
  assert_eq(nn, [1, 2, 0])
}

///|
test "nearest_neighbors: respects k limit" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::new()
  tree.insert(@rtree.Entry(make_unit_rect(5.0, 5.0), 0))
  tree.insert(@rtree.Entry(make_unit_rect(0.0, 0.0), 1))
  tree.insert(@rtree.Entry(make_unit_rect(3.0, 3.0), 2))
  let nn = tree.nearest_neighbors(@type.Coord(0.0, 0.0), Some(2))
  assert_eq(nn, [1, 2])
}

///|
test "drain: returns all and leaves empty" {
  let tree : @rtree.RTree[Int] = @rtree.RTree::new()
  for i in 0..<10 {
    tree.insert(@rtree.Entry(make_unit_rect(i.to_double(), 0.0), i))
  }
  let drained = tree.drain()
  drained.sort()
  assert_eq(drained, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
  assert_true(tree.is_empty())
  assert_eq(tree.size(), 0)
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
