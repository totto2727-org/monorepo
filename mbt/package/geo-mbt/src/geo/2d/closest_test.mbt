// Tests for closest_point, line_intersection, line_locate, line_interpolate.

///|
test "closest_point_on_line: midpoint" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let result = closest_point_on_line(l, @type.Coord::new(5.0, 5.0))
  match result {
    SinglePoint(c) => assert_true(c == @type.Coord::new(5.0, 0.0))
    _ => abort("expected SinglePoint")
  }
}

///|
test "closest_point_on_line: clamped to start" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let result = closest_point_on_line(l, @type.Coord::new(-5.0, 5.0))
  match result {
    SinglePoint(c) => assert_true(c == @type.Coord::new(0.0, 0.0))
    _ => abort("expected SinglePoint")
  }
}

///|
test "closest_point_on_line: target on line" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let result = closest_point_on_line(l, @type.Coord::new(5.0, 0.0))
  match result {
    Intersection(c) => assert_true(c == @type.Coord::new(5.0, 0.0))
    _ => abort("expected Intersection")
  }
}

///|
test "line_intersection: classic crossing" {
  let l1 = @type.Line::from_tuples((0.0, 0.0), (10.0, 10.0))
  let l2 = @type.Line::from_tuples((0.0, 10.0), (10.0, 0.0))
  match line_intersection(l1, l2) {
    Some(SinglePoint(c, proper)) => {
      assert_true((c.x() - 5.0).abs() < 1.0e-9)
      assert_true((c.y() - 5.0).abs() < 1.0e-9)
      assert_true(proper)
    }
    _ => abort("expected SinglePoint")
  }
}

///|
test "line_intersection: parallel non-overlapping" {
  let l1 = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let l2 = @type.Line::from_tuples((0.0, 1.0), (10.0, 1.0))
  assert_true(line_intersection(l1, l2) == None)
}

///|
test "line_intersection: collinear overlapping" {
  let l1 = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let l2 = @type.Line::from_tuples((5.0, 0.0), (15.0, 0.0))
  match line_intersection(l1, l2) {
    Some(Collinear(line)) => {
      assert_true(line.start() == @type.Coord::new(5.0, 0.0))
      assert_true(line.end() == @type.Coord::new(10.0, 0.0))
    }
    _ => abort("expected Collinear")
  }
}

///|
test "line_locate_point: midpoint of segment is 0.5" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let f = line_locate_point(l, @type.Coord::new(5.0, 5.0)).unwrap()
  assert_eq(f, 0.5)
}

///|
test "line_locate_point: beyond end is clamped to 1.0" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 0.0))
  let f = line_locate_point(l, @type.Coord::new(20.0, 0.0)).unwrap()
  assert_eq(f, 1.0)
}

///|
test "line_interpolate_point: f=0 is start" {
  let l = @type.Line::from_tuples((1.0, 2.0), (5.0, 10.0))
  let p = line_interpolate_point(l, 0.0)
  assert_true(p == @type.Point::new(1.0, 2.0))
}

///|
test "line_interpolate_point: f=1 is end" {
  let l = @type.Line::from_tuples((1.0, 2.0), (5.0, 10.0))
  let p = line_interpolate_point(l, 1.0)
  assert_true(p == @type.Point::new(5.0, 10.0))
}

///|
test "line_interpolate_point: f=0.5 is midpoint" {
  let l = @type.Line::from_tuples((0.0, 0.0), (10.0, 20.0))
  let p = line_interpolate_point(l, 0.5)
  assert_true(p == @type.Point::new(5.0, 10.0))
}

///|
test "line_string_interpolate_point: half-way along" {
  let ls = @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
  ])
  // Total length = 20; half = 10 → at (10, 0)
  let p = line_string_interpolate_point(ls, 0.5).unwrap()
  assert_true((p.x() - 10.0).abs() < 1.0e-9)
  assert_true(p.y().abs() < 1.0e-9)
}
