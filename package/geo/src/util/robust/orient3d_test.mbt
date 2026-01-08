///|
test "orient3d - basic cases" {
  let pa = @geojson.Position3D::new((1.0, 0.0, 1.0))
  let pb = @geojson.Position3D::new((-1.0, 0.0, -1.0))
  let pc = @geojson.Position3D::new((-1.0, 0.0, 0.0))
  let min_positive = 2.2250738585072014e-308
  let p1 = @geojson.Position3D::new((min_positive, min_positive, min_positive))
  let p2 = @geojson.Position3D::new(
    (-min_positive, -min_positive, -min_positive),
  )
  let p3 = @geojson.Position3D::new((0.0, 0.0, 0.0))
  let det1 = orient3d(pa, pb, pc, p1)
  assert_true(det1 == -1.0 || signum(det1) == -1.0)
  let det2 = orient3d(pa, pb, pc, p2)
  assert_true(det2 == 1.0 || signum(det2) == 1.0)
  let det3 = orient3d(pa, pb, pc, p3)
  assert_true(det3 == 0.0 || signum(det3) == 0.0)
}

///|
test "orient3d - fixtures" {
  let content = @fs.read_file_to_string("src/util/robust/fixture/orient3d.txt")
  let fixtures = parse_fixture_lines(content)
  for i, fixture in fixtures {
    if fixture.length() == 13 {
      let res = orient3d(
        @geojson.Position3D::new((fixture[0], fixture[1], fixture[2])),
        @geojson.Position3D::new((fixture[3], fixture[4], fixture[5])),
        @geojson.Position3D::new((fixture[6], fixture[7], fixture[8])),
        @geojson.Position3D::new((fixture[9], fixture[10], fixture[11])),
      )
      let sign = fixture[12]
      assert_true(
        signum(res) == signum(sign),
        msg="Line \{i + 1}: Result sign (\{res}) and fixture sign (\{sign}) should match",
      )
    }
  }
}
