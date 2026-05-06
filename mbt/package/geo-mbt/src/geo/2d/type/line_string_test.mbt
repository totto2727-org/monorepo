// Tests ported from georust/geo-types geometry/line_string.rs doctests.

///|
test "LineString::from_tuples and length" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  assert_eq(ls.length(), 3)
  assert_true(!ls.is_empty())
}

///|
test "LineString empty" {
  let ls = @type.LineString::LineString([])
  assert_true(ls.is_empty())
  assert_true(!ls.is_closed())
  assert_eq(ls.lines().length(), 0)
}

///|
test "LineString::empty equivalent to LineString([])" {
  let a = @type.LineString::empty()
  let b = @type.LineString::LineString([])
  assert_true(a == b)
  assert_true(a.is_empty())
  assert_eq(a.length(), 0)
}

///|
test "LineString is_closed" {
  let open = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 2.0)])
  assert_true(!open.is_closed())
  let closed = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 1.0),
    (2.0, 0.0),
    (0.0, 0.0),
  ])
  assert_true(closed.is_closed())
}

///|
test "LineString lines (segments)" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 0.0)])
  let segments = ls.lines()
  assert_eq(segments.length(), 2)
  assert_true(segments[0] == @type.Line::from_tuples((0.0, 0.0), (1.0, 1.0)))
  assert_true(segments[1] == @type.Line::from_tuples((1.0, 1.0), (2.0, 0.0)))
}

///|
test "LineString closed: returns a closed copy without mutating self" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 0.0)])
  let len_before = ls.length()
  let was_closed_before = ls.is_closed()
  let c = ls.closed()
  assert_true(c.is_closed())
  assert_eq(c.length(), 4)
  // Original is untouched (immutable semantics).
  assert_eq(ls.length(), len_before)
  assert_eq(ls.is_closed(), was_closed_before)
}

///|
test "LineString closed: already-closed input returns self (no copy)" {
  let already_closed = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 1.0),
    (2.0, 0.0),
    (0.0, 0.0),
  ])
  let c = already_closed.closed()
  // No allocation expected; we observe via structural equality + same length.
  assert_eq(c.length(), already_closed.length())
  assert_true(c == already_closed)
}

///|
test "LineString closed: empty input returns self" {
  let empty = @type.LineString::empty()
  let c = empty.closed()
  assert_eq(c.length(), 0)
  assert_true(c == empty)
}

///|
test "LineString points (eager)" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 2.0), (3.0, 4.0)])
  let pts = ls.points()
  assert_eq(pts.length(), 3)
  assert_true(pts[0] == @type.Point::Point(0.0, 0.0))
  assert_true(pts[1] == @type.Point::Point(1.0, 2.0))
  assert_true(pts[2] == @type.Point::Point(3.0, 4.0))
}

///|
test "LineString points: empty line string yields empty array" {
  let ls = @type.LineString::LineString([])
  assert_eq(ls.points().length(), 0)
}

///|
test "LineString points_iter (lazy) collects to same as points()" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 2.0), (3.0, 4.0)])
  let from_iter = ls.points_iter().collect()
  let eager = ls.points()
  assert_eq(from_iter.length(), eager.length())
  for i = 0; i < eager.length(); i = i + 1 {
    assert_true(from_iter[i] == eager[i])
  }
}

///|
test "LineString points_iter: take first only without materialising rest" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 2.0), (3.0, 4.0)])
  let head = ls.points_iter().take(1).collect()
  assert_eq(head.length(), 1)
  assert_true(head[0] == @type.Point::Point(0.0, 0.0))
}

///|
test "LineString rev_lines: reversed order with swapped endpoints" {
  // Mirror the Rust geo doctest for rev_lines with coords [(0,0), (5,0), (7,9)]
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.0), (7.0, 9.0)])
  let segs = ls.rev_lines()
  assert_eq(segs.length(), 2)
  assert_true(segs[0] == @type.Line::from_tuples((7.0, 9.0), (5.0, 0.0)))
  assert_true(segs[1] == @type.Line::from_tuples((5.0, 0.0), (0.0, 0.0)))
}

///|
test "LineString rev_lines: empty / single-coord yields empty" {
  let empty = @type.LineString::LineString([])
  assert_eq(empty.rev_lines().length(), 0)
  let one = @type.LineString::from_tuples([(1.0, 2.0)])
  assert_eq(one.rev_lines().length(), 0)
}

///|
test "LineString rev_lines is the reverse of lines (with swapped endpoints)" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 1.0),
    (2.0, 0.0),
    (3.0, 5.0),
  ])
  let forward = ls.lines()
  let reverse = ls.rev_lines()
  assert_eq(forward.length(), reverse.length())
  let n = forward.length()
  for i = 0; i < n; i = i + 1 {
    let f = forward[n - 1 - i]
    let r = reverse[i]
    assert_true(r.start() == f.end())
    assert_true(r.end() == f.start())
  }
}

///|
test "LineString lines_iter (lazy) collects to same as lines()" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 1.0), (2.0, 0.0)])
  let from_iter = ls.lines_iter().collect()
  let eager = ls.lines()
  assert_eq(from_iter.length(), eager.length())
  for i = 0; i < eager.length(); i = i + 1 {
    assert_true(from_iter[i] == eager[i])
  }
}

///|
test "LineString lines_iter: empty / single-coord yields no elements" {
  let empty = @type.LineString::empty()
  assert_eq(empty.lines_iter().collect().length(), 0)
  let one = @type.LineString::from_tuples([(1.0, 2.0)])
  assert_eq(one.lines_iter().collect().length(), 0)
}

///|
test "LineString lines_iter: take short-circuits without materialising rest" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 1.0),
    (2.0, 0.0),
    (3.0, 5.0),
  ])
  let head = ls.lines_iter().take(1).collect()
  assert_eq(head.length(), 1)
  assert_true(head[0] == @type.Line::from_tuples((0.0, 0.0), (1.0, 1.0)))
}

///|
test "LineString rev_lines_iter (lazy) collects to same as rev_lines()" {
  let ls = @type.LineString::from_tuples([(0.0, 0.0), (5.0, 0.0), (7.0, 9.0)])
  let from_iter = ls.rev_lines_iter().collect()
  let eager = ls.rev_lines()
  assert_eq(from_iter.length(), eager.length())
  for i = 0; i < eager.length(); i = i + 1 {
    assert_true(from_iter[i] == eager[i])
  }
}

///|
test "LineString rev_lines_iter: empty / single-coord yields no elements" {
  let empty = @type.LineString::empty()
  assert_eq(empty.rev_lines_iter().collect().length(), 0)
  let one = @type.LineString::from_tuples([(1.0, 2.0)])
  assert_eq(one.rev_lines_iter().collect().length(), 0)
}

///|
test "LineString rev_lines_iter: take short-circuits without materialising rest" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 1.0),
    (2.0, 0.0),
    (3.0, 5.0),
  ])
  let head = ls.rev_lines_iter().take(1).collect()
  assert_eq(head.length(), 1)
  // First item of the reverse iterator is the last forward segment, swapped.
  assert_true(head[0] == @type.Line::from_tuples((3.0, 5.0), (2.0, 0.0)))
}
