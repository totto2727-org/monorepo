///|
test "orient2d - counterclockwise" {
  let result = orient2d(
    @geojson.Position2D::new((-1.0, -1.0)),
    @geojson.Position2D::new((1.0, 1.0)),
    @geojson.Position2D::new((-1.0, 1.0)),
  )
  assert_true(result > 0.0)
}

///|
test "orient2d - clockwise" {
  let result = orient2d(
    @geojson.Position2D::new((-1.0, -1.0)),
    @geojson.Position2D::new((1.0, 1.0)),
    @geojson.Position2D::new((1.0, -1.0)),
  )
  assert_true(result < 0.0)
}

///|
test "orient2d - collinear" {
  let result = orient2d(
    @geojson.Position2D::new((-1.0, -1.0)),
    @geojson.Position2D::new((1.0, 1.0)),
    @geojson.Position2D::new((0.0, 0.0)),
  )
  assert_eq(result, 0.0)
}

///|
test "orient2d" {
  let min_positive = 2.2250738585072014e-308
  let p_from = @geojson.Position2D::new((-1.0, -1.0))
  let p_to = @geojson.Position2D::new((1.0, 1.0))
  let p1 = @geojson.Position2D::new((min_positive, min_positive))
  let p2 = @geojson.Position2D::new((-min_positive, -min_positive))
  let p3 = @geojson.Position2D::new((-min_positive, min_positive))
  let p4 = @geojson.Position2D::new((min_positive, -min_positive))
  let det1 = orient2d(p_from, p_to, p1)
  assert_true(det1 == 0.0 || signum(det1) == 0.0)
  let det2 = orient2d(p_from, p_to, p2)
  assert_true(det2 == 0.0 || signum(det2) == 0.0)
  let det3 = orient2d(p_from, p_to, p3)
  assert_true(det3 == 1.0 || signum(det3) == 1.0)
  let det4 = orient2d(p_from, p_to, p4)
  assert_true(det4 == -1.0 || signum(det4) == -1.0)
}

///|
test "orient2d fixtures" {
  let content = @fs.read_file_to_string("src/util/robust/fixture/orient2d.txt")
  let fixtures = parse_fixture_lines(content)
  for i = 0; i < fixtures.length(); i = i + 1 {
    let fixture = fixtures[i]
    if fixture.length() == 7 {
      let res = orient2d(
        @geojson.Position2D::new((fixture[0], fixture[1])),
        @geojson.Position2D::new((fixture[2], fixture[3])),
        @geojson.Position2D::new((fixture[4], fixture[5])),
      )
      let sign = fixture[6]
      assert_true(
        signum(res) == signum(sign),
        msg="Line \{i + 1}: Result sign (\{res}) and fixture sign (\{sign}) should match",
      )
    }
  }
}
