// Tests for line_intersection.mbt.

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
      assert_true(line.start() == @type.Coord(5.0, 0.0))
      assert_true(line.end() == @type.Coord(10.0, 0.0))
    }
    _ => abort("expected Collinear")
  }
}
