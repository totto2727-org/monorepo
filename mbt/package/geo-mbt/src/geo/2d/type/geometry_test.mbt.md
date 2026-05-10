# geometry.mbt

The `Geometry` enum — a tagged union over all 2D geometry types except `Coord`. Provides `try_into_<variant>` extractors that raise `MismatchedGeometry` (carrying expected and found variant names) when the runtime variant disagrees with the requested one, and an `IsEmpty` trait impl that delegates to each variant's own emptiness rule (callable via dot syntax such as `g.is_empty()` because the impl lives next to the enum).

## Public API

- `Geometry` — variants `Point` / `Line` / `LineString` / `Polygon` / `MultiPoint` / `MultiLineString` / `MultiPolygon` / `GeometryCollection` / `Rect` / `Triangle`
- `MismatchedGeometry`
- `Geometry::try_into_point`
- `Geometry::try_into_line`
- `Geometry::try_into_line_string`
- `Geometry::try_into_polygon`
- `Geometry::try_into_multi_point`
- `Geometry::try_into_multi_line_string`
- `Geometry::try_into_multi_polygon`
- `Geometry::try_into_geometry_collection`
- `Geometry::try_into_rect`
- `Geometry::try_into_triangle`
- `IsEmpty`
  - `is_empty`
- `Eq` (derived)

## Test

### `Geometry`

- Simple initialization wrapping a `Point` variant

```mbt check
///|
test "Geometry::Point - simple initialization" {
  let g = Geometry::Point(Point::Point(1.0, 2.0))
  debug_inspect(
    g,
    content=(
      #|Point({ coord: { x: 1, y: 2 } })
    ),
  )
}
```

### `MismatchedGeometry`

`MismatchedGeometry` is an opaque (read-only) suberror that can only be constructed from within the `geometry.mbt` module. Its surface — the `expected~` / `found~` payload — is exercised through the `try_into_*` mismatch tests below (e.g. `Geometry::try_into_point - mismatch raises with expected and found`).

### `Geometry::try_into_point`

| Variable | State           | Note                        |  1  |  2  |
| :------- | :-------------- | :-------------------------- | :-: | :-: |
| `self`   | `Point variant` | happy path                  |  ✓  |     |
| `self`   | `Other variant` | raises `MismatchedGeometry` |     |  ✓  |

- Happy path: returns the inner `Point`

```mbt check
///|
test "Geometry try_into_point - happy path" {
  let p = Point::Point(1.0, 2.0)
  let extracted = try! Geometry::Point(p).try_into_point()
  @test.assert_eq(extracted, p)
}
```

- Mismatch: raises with `expected="Point"` and the actual variant name

```mbt check
///|
test "Geometry try_into_point - mismatch raises with expected and found" {
  let g = Geometry::Line(Line::from_tuples((0.0, 0.0), (1.0, 1.0)))
  let result = try g.try_into_point() catch {
    MismatchedGeometry(expected~, found~) => (expected, found)
  } noraise {
    _ => ("(unreachable)", "(unreachable)")
  }
  @test.assert_eq(result, ("Point", "Line"))
}
```

### `Geometry::try_into_line`

- Happy path: returns the inner `Line`

```mbt check
///|
test "Geometry try_into_line - happy path" {
  let line = Line::from_tuples((0.0, 0.0), (1.0, 1.0))
  let extracted = try! Geometry::Line(line).try_into_line()
  @test.assert_eq(extracted, line)
}
```

### `Geometry::try_into_line_string`

- Happy path: returns the inner `LineString`

```mbt check
///|
test "Geometry try_into_line_string - happy path" {
  let ls = LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let extracted = try! Geometry::LineString(ls).try_into_line_string()
  @test.assert_eq(extracted, ls)
}
```

### `Geometry::try_into_polygon`

- Happy path: returns the inner `Polygon`

```mbt check
///|
test "Geometry try_into_polygon - happy path" {
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = Polygon::Polygon(exterior, [])
  let extracted = try! Geometry::Polygon(polygon).try_into_polygon()
  @test.assert_eq(extracted, polygon)
}
```

### `Geometry::try_into_multi_point`

- Happy path: returns the inner `MultiPoint`

```mbt check
///|
test "Geometry try_into_multi_point - happy path" {
  let mp = MultiPoint::from_tuples([(0.0, 0.0), (1.0, 1.0)])
  let extracted = try! Geometry::MultiPoint(mp).try_into_multi_point()
  @test.assert_eq(extracted, mp)
}
```

### `Geometry::try_into_multi_line_string`

- Happy path: returns the inner `MultiLineString`

```mbt check
///|
test "Geometry try_into_multi_line_string - happy path" {
  let mls = MultiLineString::MultiLineString([
    LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
  ])
  let extracted = try! Geometry::MultiLineString(mls).try_into_multi_line_string()
  @test.assert_eq(extracted, mls)
}
```

### `Geometry::try_into_multi_polygon`

- Happy path: returns the inner `MultiPolygon`

```mbt check
///|
test "Geometry try_into_multi_polygon - happy path" {
  let exterior = LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)])
  let mpoly = MultiPolygon::MultiPolygon([Polygon::Polygon(exterior, [])])
  let extracted = try! Geometry::MultiPolygon(mpoly).try_into_multi_polygon()
  @test.assert_eq(extracted, mpoly)
}
```

### `Geometry::try_into_geometry_collection`

- Happy path: returns the inner `GeometryCollection`

```mbt check
///|
test "Geometry try_into_geometry_collection - happy path" {
  let gc = GeometryCollection::GeometryCollection([
    Geometry::Point(Point::Point(1.0, 2.0)),
  ])
  let extracted = try! Geometry::GeometryCollection(gc).try_into_geometry_collection()
  @test.assert_eq(extracted, gc)
}
```

### `Geometry::try_into_rect`

- Happy path: returns the inner `Rect`

```mbt check
///|
test "Geometry try_into_rect - happy path" {
  let r = Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(1.0, 1.0))
  let extracted = try! Geometry::Rect(r).try_into_rect()
  @test.assert_eq(extracted, r)
}
```

### `Geometry::try_into_triangle`

- Happy path: returns the inner `Triangle`

```mbt check
///|
test "Geometry try_into_triangle - happy path" {
  let t = Triangle::Triangle(
    Coord::Coord(0.0, 0.0),
    Coord::Coord(1.0, 0.0),
    Coord::Coord(0.0, 1.0),
  )
  let extracted = try! Geometry::Triangle(t).try_into_triangle()
  @test.assert_eq(extracted, t)
}
```

- Round-robin cross-variant mismatch covering every `try_into_*` mismatch path and every `Geometry` variant in the `found` slot

```mbt check
///|
test "Geometry try_into_* - exhaustive mismatch sweep across all 10 variants" {
  // Each row pairs a source variant with a try_into_* call that does NOT
  // match it. This visits every try_into_*'s mismatch branch (10 of 10) and
  // every Geometry variant in the `found` slot (10 of 10).
  let exterior = LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = Polygon::Polygon(exterior, [])
  let mpoly = MultiPolygon::MultiPolygon([polygon])
  let mls = MultiLineString::MultiLineString([
    LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
  ])
  let gc = GeometryCollection::GeometryCollection([
    Geometry::Point(Point::Point(0.0, 0.0)),
  ])
  fn extract(thunk : () -> Unit raise MismatchedGeometry) -> (String, String) {
    try {
      thunk()
      ("(unreachable)", "(unreachable)")
    } catch {
      MismatchedGeometry(expected~, found~) => (expected, found)
    }
  }
  let cases = [
    // (source variant, try_into_* call, expected (variant_name(target)), found (variant_name(source)))
    (
      extract(() => {
        let _ = Geometry::Point(Point::Point(0.0, 0.0)).try_into_line()
      }),
      ("Line", "Point"),
    ),
    (
      extract(() => {
        let _ = Geometry::Line(Line::from_tuples((0.0, 0.0), (1.0, 1.0))).try_into_line_string()
      }),
      ("LineString", "Line"),
    ),
    (
      extract(() => {
        let _ = Geometry::LineString(
          LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
        ).try_into_polygon()
      }),
      ("Polygon", "LineString"),
    ),
    (
      extract(() => {
        let _ = Geometry::Polygon(polygon).try_into_multi_point()
      }),
      ("MultiPoint", "Polygon"),
    ),
    (
      extract(() => {
        let _ = Geometry::MultiPoint(MultiPoint::from_tuples([(0.0, 0.0)])).try_into_multi_line_string()
      }),
      ("MultiLineString", "MultiPoint"),
    ),
    (
      extract(() => {
        let _ = Geometry::MultiLineString(mls).try_into_multi_polygon()
      }),
      ("MultiPolygon", "MultiLineString"),
    ),
    (
      extract(() => {
        let _ = Geometry::MultiPolygon(mpoly).try_into_geometry_collection()
      }),
      ("GeometryCollection", "MultiPolygon"),
    ),
    (
      extract(() => {
        let _ = Geometry::GeometryCollection(gc).try_into_rect()
      }),
      ("Rect", "GeometryCollection"),
    ),
    (
      extract(() => {
        let _ = Geometry::Rect(
          Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(1.0, 1.0)),
        ).try_into_triangle()
      }),
      ("Triangle", "Rect"),
    ),
    (
      extract(() => {
        let _ = Geometry::Triangle(
          Triangle::Triangle(
            Coord::Coord(0.0, 0.0),
            Coord::Coord(1.0, 0.0),
            Coord::Coord(0.0, 1.0),
          ),
        ).try_into_point()
      }),
      ("Point", "Triangle"),
    ),
  ]
  for case in cases {
    @test.assert_eq(case.0, case.1)
  }
}
```

### `IsEmpty`

| Variable | State                                | Note                                    |  1  |  2  |  3  |  4  |  5  |  6  |  7  |
| :------- | :----------------------------------- | :-------------------------------------- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| `self`   | `Point / Line / Rect / Triangle`     | always false                            |  ✓  |     |     |     |     |     |     |
| `self`   | `LineString` (empty / non-empty)     | delegates to `LineString::is_empty`     |     |  ✓  |     |     |     |     |     |
| `self`   | `MultiPoint` (empty / non-empty)     | delegates to `MultiPoint::is_empty`     |     |     |  ✓  |     |     |     |     |
| `self`   | `MultiLineString` (all components)   | true iff every component is empty       |     |     |     |  ✓  |     |     |     |
| `self`   | `Polygon` (exterior empty)           | true iff exterior is empty              |     |     |     |     |  ✓  |     |     |
| `self`   | `MultiPolygon` (all exteriors empty) | true iff every polygon's exterior empty |     |     |     |     |     |  ✓  |     |
| `self`   | `GeometryCollection` (all empty)     | true iff every geometry is empty        |     |     |     |     |     |     |  ✓  |

#### `is_empty`

- Single-geometry variants are never empty (callable as `g.is_empty()` via dot syntax)

```mbt check
///|
test "Geometry IsEmpty::is_empty - single-geometry variants are never empty" {
  let p = Geometry::Point(Point::Point(0.0, 0.0))
  let l = Geometry::Line(Line::from_tuples((0.0, 0.0), (1.0, 1.0)))
  let r = Geometry::Rect(
    Rect::Rect(Coord::Coord(0.0, 0.0), Coord::Coord(1.0, 1.0)),
  )
  let t = Geometry::Triangle(
    Triangle::Triangle(
      Coord::Coord(0.0, 0.0),
      Coord::Coord(1.0, 0.0),
      Coord::Coord(0.0, 1.0),
    ),
  )
  assert_false(p.is_empty())
  assert_false(l.is_empty())
  assert_false(r.is_empty())
  assert_false(t.is_empty())
  // Spot-check explicit trait dispatch matches the dot-syntax form.
  @test.assert_eq(IsEmpty::is_empty(p), p.is_empty())
}
```

- `LineString` variant delegates

```mbt check
///|
test "Geometry IsEmpty::is_empty - LineString delegates" {
  let empty = Geometry::LineString(LineString::empty())
  let non_empty = Geometry::LineString(
    LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
  )
  assert_true(empty.is_empty())
  assert_false(non_empty.is_empty())
}
```

- `MultiPoint` variant delegates

```mbt check
///|
test "Geometry IsEmpty::is_empty - MultiPoint delegates" {
  let empty = Geometry::MultiPoint(MultiPoint::empty())
  let non_empty = Geometry::MultiPoint(MultiPoint::from_tuples([(0.0, 0.0)]))
  assert_true(empty.is_empty())
  assert_false(non_empty.is_empty())
}
```

- `MultiLineString` is empty when all components are empty

```mbt check
///|
test "Geometry IsEmpty::is_empty - MultiLineString true when all components empty" {
  let all_empty = Geometry::MultiLineString(
    MultiLineString::MultiLineString([LineString::empty(), LineString::empty()]),
  )
  let any_filled = Geometry::MultiLineString(
    MultiLineString::MultiLineString([
      LineString::empty(),
      LineString::from_tuples([(0.0, 0.0), (1.0, 1.0)]),
    ]),
  )
  assert_true(all_empty.is_empty())
  assert_false(any_filled.is_empty())
}
```

- `Polygon` is empty when exterior is empty

```mbt check
///|
test "Geometry IsEmpty::is_empty - Polygon true when exterior is empty" {
  let empty_exterior = Geometry::Polygon(
    Polygon::Polygon(LineString::empty(), []),
  )
  let filled_exterior = Geometry::Polygon(
    Polygon::Polygon(
      LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)]),
      [],
    ),
  )
  assert_true(empty_exterior.is_empty())
  assert_false(filled_exterior.is_empty())
}
```

- `MultiPolygon` is empty when every polygon's exterior is empty

```mbt check
///|
test "Geometry IsEmpty::is_empty - MultiPolygon true when every exterior empty" {
  let all_empty = Geometry::MultiPolygon(
    MultiPolygon::MultiPolygon([
      Polygon::Polygon(LineString::empty(), []),
      Polygon::Polygon(LineString::empty(), []),
    ]),
  )
  let any_filled = Geometry::MultiPolygon(
    MultiPolygon::MultiPolygon([
      Polygon::Polygon(LineString::empty(), []),
      Polygon::Polygon(
        LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0)]),
        [],
      ),
    ]),
  )
  assert_true(all_empty.is_empty())
  assert_false(any_filled.is_empty())
}
```

- `GeometryCollection` is empty when every contained geometry is empty (recursive)

```mbt check
///|
test "Geometry IsEmpty::is_empty - GeometryCollection true when all geometries empty" {
  let all_empty = Geometry::GeometryCollection(
    GeometryCollection::GeometryCollection([
      Geometry::LineString(LineString::empty()),
      Geometry::MultiPoint(MultiPoint::empty()),
    ]),
  )
  let any_filled = Geometry::GeometryCollection(
    GeometryCollection::GeometryCollection([
      Geometry::LineString(LineString::empty()),
      Geometry::Point(Point::Point(0.0, 0.0)),
    ]),
  )
  assert_true(all_empty.is_empty())
  assert_false(any_filled.is_empty())
}
```

### `Eq` (derived)

#### `op_equal`

- Equal and unequal geometries

```mbt check
///|
test "Geometry Eq::op_equal - equal and unequal" {
  let a = Geometry::Point(Point::Point(1.0, 2.0))
  let b = Geometry::Point(Point::Point(1.0, 2.0))
  let c = Geometry::Point(Point::Point(3.0, 4.0))
  let d = Geometry::Line(Line::from_tuples((1.0, 2.0), (3.0, 4.0)))
  @test.assert_eq(a, b)
  @test.assert_not_eq(a, c)
  @test.assert_not_eq(a, d)
}
```
