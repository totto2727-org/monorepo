///|
test "insphere" {
  let pa = @geojson.Position3D::new((1.0, 0.0, 0.0))
  let pb = @geojson.Position3D::new((0.0, 1.0, 0.0))
  let pc = @geojson.Position3D::new((0.0, 0.0, 1.0))
  let pd = @geojson.Position3D::new((0.0, -1.0, 0.0))
  let pe1 = @geojson.Position3D::new((-1.01, 0.0, 0.0))
  let pe2 = @geojson.Position3D::new((0.0, 0.0, 0.99))
  let pe3 = @geojson.Position3D::new((0.0, 0.0, -1.0))
  let det1 = insphere(pa, pb, pc, pd, pe1)
  assert_true(det1 < 0.0)
  let det2 = insphere(pa, pb, pc, pd, pe2)
  assert_true(det2 > 0.0)
  let det3 = insphere(pa, pb, pc, pd, pe3)
  assert_eq(det3, 0.0)
}

///|
test "insphere fixtures" {
  let content = @fs.read_file_to_string("src/util/robust/fixture/insphere.txt")
  let fixtures = parse_fixture_lines(content)
  for i, fixture in fixtures {
    if fixture.length() == 16 {
      let res = insphere(
        @geojson.Position3D::new((fixture[0], fixture[1], fixture[2])),
        @geojson.Position3D::new((fixture[3], fixture[4], fixture[5])),
        @geojson.Position3D::new((fixture[6], fixture[7], fixture[8])),
        @geojson.Position3D::new((fixture[9], fixture[10], fixture[11])),
        @geojson.Position3D::new((fixture[12], fixture[13], fixture[14])),
      )
      let sign = fixture[15]
      assert_true(
        signum(res) == signum(sign),
        msg="Line \{i + 1}: Result sign (\{res}) and fixture sign (\{sign}) should match",
      )
    }
  }
}
