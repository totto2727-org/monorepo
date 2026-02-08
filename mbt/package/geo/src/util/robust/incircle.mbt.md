# incircle.mbt

Adaptive Precision Floating-Point Arithmetic and Fast Robust Predicates for **incircle**.

## Public API

- `incircle`

## Test

### incircle

- incircle - basic cases

```mbt check
///|
test {
  let p_a = @type.XY::new(0.0, 0.0)
  let p_b = @type.XY::new(1.0, 0.0)
  let p_c = @type.XY::new(0.0, 1.0)
  let p_d_inside = @type.XY::new(0.1, 0.1)
  let p_d_outside = @type.XY::new(2.0, 2.0)
  let p_d_cocircular = @type.XY::new(1.0, 1.0)
  let res_in = incircle(p_a, p_b, p_c, p_d_inside)
  assert_true(res_in > 0.0)
  let res_out = incircle(p_a, p_b, p_c, p_d_outside)
  assert_true(res_out < 0.0)
  let res_co = incircle(p_a, p_b, p_c, p_d_cocircular)
  assert_eq(res_co, 0.0)
}
```

- incircle - fixtures

```mbt check
///|
test {
  let content = @fs.read_file_to_string("src/util/robust/fixture/incircle.txt")
  let fixtures = parse_fixture_lines(content)
  for i = 0; i < fixtures.length(); i = i + 1 {
    let fixture = fixtures[i]
    if fixture.length() == 9 {
      let res = incircle(
        @type.XY::new(fixture[0], fixture[1]),
        @type.XY::new(fixture[2], fixture[3]),
        @type.XY::new(fixture[4], fixture[5]),
        @type.XY::new(fixture[6], fixture[7]),
      )
      let sign = fixture[8]
      assert_true(
        signum(res) == signum(sign),
        msg="Line \{i + 1}: Result sign (\{res}) and fixture sign (\{sign}) should match",
      )
    }
  }
}
```
