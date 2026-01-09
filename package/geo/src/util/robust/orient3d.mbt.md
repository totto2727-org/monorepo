# orient3d.mbt

Adaptive Precision Floating-Point Arithmetic and Fast Robust Predicates for **orient3d**.

## Public API

- `orient3d`

## Test

### orient3d

- orient3d - basic cases

```mbt check
///|
test {
  let p1 = @type.XYZ::new(0.0, 0.0, 0.0)
  let p2 = @type.XYZ::new(1.0, 0.0, 0.0)
  let p3 = @type.XYZ::new(0.0, 1.0, 0.0)
  let p4 = @type.XYZ::new(0.0, 0.0, 1.0)
  let res = orient3d(p1, p2, p3, p4)
  // p1, p2, p3 are CCW from above, p4 is above plane (z=1).
  // orient3d returns -ve if pd lies above plane.
  assert_true(res < 0.0)
}
```

- orient3d - fixtures

```mbt check
///|
test {
  let content = @fs.read_file_to_string("src/util/robust/fixture/orient3d.txt")
  let fixtures = parse_fixture_lines(content)
  for i = 0; i < fixtures.length(); i = i + 1 {
    let fixture = fixtures[i]
    if fixture.length() == 13 {
      let res = orient3d(
        @type.XYZ::new(fixture[0], fixture[1], fixture[2]),
        @type.XYZ::new(fixture[3], fixture[4], fixture[5]),
        @type.XYZ::new(fixture[6], fixture[7], fixture[8]),
        @type.XYZ::new(fixture[9], fixture[10], fixture[11]),
      )
      let sign = fixture[12]
      assert_true(
        signum(res) == signum(sign),
        msg="Line \{i + 1}: Result sign (\{res}) and fixture sign (\{sign}) should match",
      )
    }
  }
}
```
