///|
test "insphere" {
  let pa = @geojson.Position::new3D(1.0, 0.0, 0.0)
  let pb = @geojson.Position::new3D(0.0, 1.0, 0.0)
  let pc = @geojson.Position::new3D(0.0, 0.0, 1.0)
  let pd = @geojson.Position::new3D(0.0, -1.0, 0.0)
  let pe1 = @geojson.Position::new3D(-1.01, 0.0, 0.0)
  let pe2 = @geojson.Position::new3D(0.0, 0.0, 0.99)
  let pe3 = @geojson.Position::new3D(0.0, 0.0, -1.0)
  let det1 = insphere(pa, pb, pc, pd, pe1)
  assert_true(det1 < 0.0)
  let det2 = insphere(pa, pb, pc, pd, pe2)
  assert_true(det2 > 0.0)
  let det3 = insphere(pa, pb, pc, pd, pe3)
  assert_eq(det3, 0.0)
}

///|
test "panic_insphere - error on 2d position" {
  let pa = @geojson.Position::new3D(1.0, 0.0, 0.0)
  let pb = @geojson.Position::new3D(0.0, 1.0, 0.0)
  let pc = @geojson.Position::new3D(0.0, 0.0, 1.0)
  let pd = @geojson.Position::new3D(0.0, -1.0, 0.0)
  let pe_invalid = @geojson.Position::new2D(0.0, 0.0)
  insphere(pa, pb, pc, pd, pe_invalid) |> ignore
}

///|
test "insphere fixtures" {
  let content = @fs.read_file_to_string("src/util/robust/fixture/insphere.txt")
  let fixtures = parse_fixture_lines(content)
  for i, fixture in fixtures {
    if fixture.length() == 16 {
      let res = insphere(
        @geojson.Position::new3D(fixture[0], fixture[1], fixture[2]),
        @geojson.Position::new3D(fixture[3], fixture[4], fixture[5]),
        @geojson.Position::new3D(fixture[6], fixture[7], fixture[8]),
        @geojson.Position::new3D(fixture[9], fixture[10], fixture[11]),
        @geojson.Position::new3D(fixture[12], fixture[13], fixture[14]),
      )
      let sign = fixture[15]
      assert_true(
        signum(res) == signum(sign),
        msg="Line \{i + 1}: Result sign (\{res}) and fixture sign (\{sign}) should match",
      )
    }
  }
}
