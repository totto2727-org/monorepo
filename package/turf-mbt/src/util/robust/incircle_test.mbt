///|
test "incircle" {
  let min_positive = 2.2250738585072014e-308
  let p_from = @geojson.Position::new2D(-1.0, -1.0)
  let p_to = @geojson.Position::new2D(1.0, 1.0)
  let p_left = @geojson.Position::new2D(-min_positive, min_positive)
  let p_right = @geojson.Position::new2D(min_positive, -min_positive)
  let p_query = @geojson.Position::new2D(2.0, 2.0)
  assert_true(incircle(p_from, p_left, p_to, p_query) > 0.0)
  assert_true(incircle(p_from, p_to, p_right, p_query) > 0.0)
}

///|
test "issue48_a" {
  let pa = @geojson.Position::new2D(2.1045541600524288e-15, -1.0000000000000016)
  let pb = @geojson.Position::new2D(1.000000000000005, -3.350874324301223e-16)
  let pc = @geojson.Position::new2D(7.553997323229233e-15, 0.9999999999999958)
  let pd = @geojson.Position::new2D(-0.9999999999999922, -7.073397829693697e-15)
  let result = incircle(pa, pb, pc, pd)
  assert_true(result != 1.9217716744382023e-16)
  assert_true(result < 0.0)
}

///|
test "issue48_b" {
  let pa = @geojson.Position::new2D(9.128561612013288e-15, -1.0000000000000029)
  let pb = @geojson.Position::new2D(1.0000000000000044, -5.451395142523081e-15)
  let pc = @geojson.Position::new2D(3.851214418148064e-15, 0.9999999999999961)
  let pd = @geojson.Position::new2D(
    -0.9999999999999946, -6.6797960341085084e-15,
  )
  let result = incircle(pa, pb, pc, pd)
  assert_true(result != -1.1074731814540733e-16)
  assert_true(result > 0.0)
}

///|
test "incircle fixtures" {
  let content = @fs.read_file_to_string("src/util/robust/fixture/incircle.txt")
  let fixtures = parse_fixture_lines(content)
  for i = 0; i < fixtures.length(); i = i + 1 {
    let fixture = fixtures[i]
    if fixture.length() == 9 {
      let res = incircle(
        @geojson.Position::new2D(fixture[0], fixture[1]),
        @geojson.Position::new2D(fixture[2], fixture[3]),
        @geojson.Position::new2D(fixture[4], fixture[5]),
        @geojson.Position::new2D(fixture[6], fixture[7]),
      )
      let sign = fixture[8]
      assert_true(
        signum(res) == signum(sign),
        msg="Line \{i + 1}: Result sign (\{res}) and fixture sign (\{sign}) should match",
      )
    }
  }
}
