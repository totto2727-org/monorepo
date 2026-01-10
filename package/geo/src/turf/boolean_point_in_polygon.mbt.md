# boolean_point_in_polygon.mbt

Determine if a point is inside a polygon or multipolygon.

## Public API

- `boolean_point_in_polygon`

## Test

### boolean_point_in_polygon

- inside simple

```mbt check
///|
test {
  let polygon = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(0.0, 0.0),
      @type.XY::new(0.0, 100.0),
      @type.XY::new(100.0, 100.0),
      @type.XY::new(100.0, 0.0),
      @type.XY::new(0.0, 0.0),
    ]),
  )
  let point = @type.Point::new(@type.XY::new(50.0, 50.0))
  inspect(@turf.boolean_point_in_polygon(point, polygon), content="true")
}
```

- outside simple

```mbt check
///|
test {
  let polygon = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(0.0, 0.0),
      @type.XY::new(0.0, 100.0),
      @type.XY::new(100.0, 100.0),
      @type.XY::new(100.0, 0.0),
      @type.XY::new(0.0, 0.0),
    ]),
  )
  let point = @type.Point::new(@type.XY::new(140.0, 150.0))
  inspect(@turf.boolean_point_in_polygon(point, polygon), content="false")
}
```

- inside concave

```mbt check
///|
test {
  let point = @type.Point::new(@type.XY::new(75.0, 75.0))
  let polygon = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(0.0, 0.0),
      @type.XY::new(50.0, 50.0),
      @type.XY::new(0.0, 100.0),
      @type.XY::new(100.0, 100.0),
      @type.XY::new(100.0, 0.0),
      @type.XY::new(0.0, 0.0),
    ]),
  )
  inspect(@turf.boolean_point_in_polygon(point, polygon), content="true")
}
```

- outside concave

```mbt check
///|
test {
  let point = @type.Point::new(@type.XY::new(25.0, 50.0))
  let polygon = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(0.0, 0.0),
      @type.XY::new(50.0, 50.0),
      @type.XY::new(0.0, 100.0),
      @type.XY::new(100.0, 100.0),
      @type.XY::new(100.0, 0.0),
      @type.XY::new(0.0, 0.0),
    ]),
  )
  inspect(@turf.boolean_point_in_polygon(point, polygon), content="false")
}
```

- boundary included

```mbt check
///|
test {
  let point = @type.Point::new(@type.XY::new(10.0, 10.0))
  let polygon = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(10.0, 10.0),
      @type.XY::new(30.0, 20.0),
      @type.XY::new(50.0, 10.0),
      @type.XY::new(30.0, 0.0),
      @type.XY::new(10.0, 10.0),
    ]),
  )
  inspect(@turf.boolean_point_in_polygon(point, polygon), content="true")
}
```

- boundary ignored

```mbt check
///|
test {
  let point = @type.Point::new(@type.XY::new(10.0, 10.0))
  let polygon = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(10.0, 10.0),
      @type.XY::new(30.0, 20.0),
      @type.XY::new(50.0, 10.0),
      @type.XY::new(30.0, 0.0),
      @type.XY::new(10.0, 10.0),
    ]),
  )
  inspect(
    @turf.boolean_point_in_polygon(point, polygon, ignore_boundary=true),
    content="false",
  )
}
```

- inside hole (outside)

```mbt check
///|
test {
  let polygon = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(0.0, 0.0),
      @type.XY::new(0.0, 100.0),
      @type.XY::new(100.0, 100.0),
      @type.XY::new(100.0, 0.0),
      @type.XY::new(0.0, 0.0),
    ]),
    interior_array=[
      @type.Ring::new([
        @type.XY::new(25.0, 25.0),
        @type.XY::new(25.0, 75.0),
        @type.XY::new(75.0, 75.0),
        @type.XY::new(75.0, 25.0),
        @type.XY::new(25.0, 25.0),
      ]),
    ],
  )
  let point = @type.Point::new(@type.XY::new(10.0, 10.0))
  inspect(@turf.boolean_point_in_polygon(point, polygon), content="true")
}
```

- in hole (inside)

```mbt check
///|
test {
  let polygon = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(0.0, 0.0),
      @type.XY::new(0.0, 100.0),
      @type.XY::new(100.0, 100.0),
      @type.XY::new(100.0, 0.0),
      @type.XY::new(0.0, 0.0),
    ]),
    interior_array=[
      @type.Ring::new([
        @type.XY::new(25.0, 25.0),
        @type.XY::new(25.0, 75.0),
        @type.XY::new(75.0, 75.0),
        @type.XY::new(75.0, 25.0),
        @type.XY::new(25.0, 25.0),
      ]),
    ],
  )
  let point = @type.Point::new(@type.XY::new(50.0, 50.0))
  inspect(@turf.boolean_point_in_polygon(point, polygon), content="false")
}
```

- issue #15

```mbt check
///|
test {
  let polygon = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(5.080336744095521, 67.89398938540765),
      @type.XY::new(0.35070899909145403, 69.32470003971179),
      @type.XY::new(-24.453622256504122, 41.146696777884564),
      @type.XY::new(-21.6445524714804, 40.43225902006474),
      @type.XY::new(5.080336744095521, 67.89398938540765),
    ]),
  )
  let point = @type.Point::new(@type.XY::new(-9.9964077, 53.8040989))
  inspect(@turf.boolean_point_in_polygon(point, polygon), content="true")
}
```

- boundary test fixtures

```mbt check
///|
test {
  let poly1 = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(10.0, 10.0),
      @type.XY::new(30.0, 20.0),
      @type.XY::new(50.0, 10.0),
      @type.XY::new(30.0, 0.0),
      @type.XY::new(10.0, 10.0),
    ]),
  )
  let poly2 = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(10.0, 0.0),
      @type.XY::new(30.0, 20.0),
      @type.XY::new(50.0, 0.0),
      @type.XY::new(30.0, 10.0),
      @type.XY::new(10.0, 0.0),
    ]),
  )
  let poly3 = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(10.0, 0.0),
      @type.XY::new(30.0, 20.0),
      @type.XY::new(50.0, 0.0),
      @type.XY::new(30.0, -20.0),
      @type.XY::new(10.0, 0.0),
    ]),
  )
  let poly4 = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(0.0, 0.0),
      @type.XY::new(0.0, 20.0),
      @type.XY::new(50.0, 20.0),
      @type.XY::new(50.0, 0.0),
      @type.XY::new(40.0, 0.0),
      @type.XY::new(30.0, 10.0),
      @type.XY::new(30.0, 0.0),
      @type.XY::new(20.0, 10.0),
      @type.XY::new(10.0, 10.0),
      @type.XY::new(10.0, 0.0),
      @type.XY::new(0.0, 0.0),
    ]),
  )
  let poly5 = @type.Polygon::new(
    @type.Ring::new([
      @type.XY::new(0.0, 20.0),
      @type.XY::new(20.0, 40.0),
      @type.XY::new(40.0, 20.0),
      @type.XY::new(20.0, 0.0),
      @type.XY::new(0.0, 20.0),
    ]),
    interior_array=[
      @type.Ring::new([
        @type.XY::new(10.0, 20.0),
        @type.XY::new(20.0, 30.0),
        @type.XY::new(30.0, 20.0),
        @type.XY::new(20.0, 10.0),
        @type.XY::new(10.0, 20.0),
      ]),
    ],
  )
  let tests = [
    (poly1, @type.Point::new(@type.XY::new(10.0, 10.0)), true),
    (poly1, @type.Point::new(@type.XY::new(30.0, 20.0)), true),
    (poly1, @type.Point::new(@type.XY::new(50.0, 10.0)), true),
    (poly1, @type.Point::new(@type.XY::new(30.0, 10.0)), true),
    (poly1, @type.Point::new(@type.XY::new(0.0, 10.0)), false),
    (poly1, @type.Point::new(@type.XY::new(60.0, 10.0)), false),
    (poly1, @type.Point::new(@type.XY::new(30.0, -10.0)), false),
    (poly1, @type.Point::new(@type.XY::new(30.0, 30.0)), false),
    (poly2, @type.Point::new(@type.XY::new(30.0, 0.0)), false),
    (poly2, @type.Point::new(@type.XY::new(0.0, 0.0)), false),
    (poly2, @type.Point::new(@type.XY::new(60.0, 0.0)), false),
    (poly3, @type.Point::new(@type.XY::new(30.0, 0.0)), true),
    (poly3, @type.Point::new(@type.XY::new(0.0, 0.0)), false),
    (poly3, @type.Point::new(@type.XY::new(60.0, 0.0)), false),
    (poly4, @type.Point::new(@type.XY::new(0.0, 20.0)), true),
    (poly4, @type.Point::new(@type.XY::new(10.0, 20.0)), true),
    (poly4, @type.Point::new(@type.XY::new(50.0, 20.0)), true),
    (poly4, @type.Point::new(@type.XY::new(0.0, 10.0)), true),
    (poly4, @type.Point::new(@type.XY::new(5.0, 10.0)), true),
    (poly4, @type.Point::new(@type.XY::new(25.0, 10.0)), true),
    (poly4, @type.Point::new(@type.XY::new(35.0, 10.0)), true),
    (poly4, @type.Point::new(@type.XY::new(0.0, 0.0)), true),
    (poly4, @type.Point::new(@type.XY::new(10.0, 0.0)), true),
    (poly4, @type.Point::new(@type.XY::new(20.0, 0.0)), false),
    (poly4, @type.Point::new(@type.XY::new(30.0, 0.0)), true),
    (poly4, @type.Point::new(@type.XY::new(40.0, 0.0)), true),
    (poly4, @type.Point::new(@type.XY::new(20.0, 10.0)), true),
    (poly4, @type.Point::new(@type.XY::new(15.0, 10.0)), true),
    (poly4, @type.Point::new(@type.XY::new(20.0, 20.0)), true),
    (poly4, @type.Point::new(@type.XY::new(20.0, 0.0)), false),
    (poly4, @type.Point::new(@type.XY::new(35.0, 0.0)), false),
    (poly4, @type.Point::new(@type.XY::new(50.0, 0.0)), true),
    (poly4, @type.Point::new(@type.XY::new(50.0, 10.0)), true),
    (poly4, @type.Point::new(@type.XY::new(5.0, 0.0)), true),
    (poly5, @type.Point::new(@type.XY::new(20.0, 30.0)), true),
    (poly5, @type.Point::new(@type.XY::new(25.0, 25.0)), true),
    (poly5, @type.Point::new(@type.XY::new(30.0, 20.0)), true),
    (poly5, @type.Point::new(@type.XY::new(25.0, 15.0)), true),
    (poly5, @type.Point::new(@type.XY::new(20.0, 10.0)), true),
    (poly5, @type.Point::new(@type.XY::new(15.0, 15.0)), true),
    (poly5, @type.Point::new(@type.XY::new(10.0, 20.0)), true),
    (poly5, @type.Point::new(@type.XY::new(15.0, 25.0)), true),
    (poly5, @type.Point::new(@type.XY::new(20.0, 20.0)), false),
  ]
  for test_case in tests {
    let (poly, pt, expected) = test_case
    assert_eq(
      @turf.boolean_point_in_polygon(pt, poly, ignore_boundary=false),
      expected,
    )
  }
}
```

- poly with hole fixture

```mbt check
///|
test {
  let pt_in_hole = @type.Point::new(
    @type.XY::new(-86.69208526611328, 36.20373274711739),
  )
  let pt_in_poly = @type.Point::new(
    @type.XY::new(-86.72229766845702, 36.20258997094334),
  )
  let pt_outside_poly = @type.Point::new(
    @type.XY::new(-86.75079345703125, 36.18527313913089),
  )
  inspect(
    @turf.boolean_point_in_polygon(pt_in_hole, @fixture.poly_with_hole),
    content="false",
  )
  inspect(
    @turf.boolean_point_in_polygon(pt_in_poly, @fixture.poly_with_hole),
    content="true",
  )
  inspect(
    @turf.boolean_point_in_polygon(pt_outside_poly, @fixture.poly_with_hole),
    content="false",
  )
}
```
