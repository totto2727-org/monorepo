# orient.mbt

Re-orient the rings of a `Polygon` (or every polygon in a `MultiPolygon`) into the requested winding convention. The `OrientDirection::Default` convention is _CCW exterior, CW interiors_ (the OGC SFA / GeoJSON canonical orientation); `OrientDirection::Reversed` flips both.

## Public API

- `OrientDirection`
- `Orient` trait — impls on `Polygon` / `MultiPolygon`
  - `orient(Self, OrientDirection) -> Self`

## Test

### `Orient` for `Polygon`

- Default direction makes a CW exterior CCW

```mbt check
///|
test "Orient::orient - Polygon Default makes exterior CCW" {
  let cw_exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 1.0),
    (1.0, 1.0),
    (1.0, 0.0),
    (0.0, 0.0),
  ])
  let oriented = Orient::orient(
    @type.Polygon::Polygon(cw_exterior, []),
    OrientDirection::Default,
  )
  let actual = match winding_order(oriented.exterior()) {
    Some(w) => w
    None => abort("expected winding order for non-degenerate exterior")
  }
  @test.assert_eq(actual, WindingOrder::CounterClockwise)
}
```

- Reversed direction flips the exterior to CW

```mbt check
///|
test "Orient::orient - Polygon Reversed makes exterior CW" {
  let ccw_exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  let oriented = Orient::orient(
    @type.Polygon::Polygon(ccw_exterior, []),
    OrientDirection::Reversed,
  )
  let actual = match winding_order(oriented.exterior()) {
    Some(w) => w
    None => abort("expected winding order for non-degenerate exterior")
  }
  @test.assert_eq(actual, WindingOrder::Clockwise)
}
```

### `Orient` for `MultiPolygon`

- Re-orients every polygon in the collection

```mbt check
///|
test "Orient::orient - MultiPolygon re-orients every polygon" {
  let cw_exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 1.0),
    (1.0, 1.0),
    (1.0, 0.0),
    (0.0, 0.0),
  ])
  let mp = @type.MultiPolygon::MultiPolygon([
    @type.Polygon::Polygon(cw_exterior, []),
  ])
  let oriented = Orient::orient(mp, OrientDirection::Default)
  let actual = match winding_order(oriented.polygons()[0].exterior()) {
    Some(w) => w
    None => abort("expected winding order for non-degenerate exterior")
  }
  @test.assert_eq(actual, WindingOrder::CounterClockwise)
}
```
