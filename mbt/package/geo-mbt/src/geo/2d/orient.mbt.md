# orient.mbt

Re-orient the rings of a `Polygon` (or every polygon in a `MultiPolygon`) into the requested winding convention. The `OrientDirection::Default` convention is _CCW exterior, CW interiors_ (the OGC SFA / GeoJSON canonical orientation); `OrientDirection::Reversed` flips both.

## Public API

- `OrientDirection`
- `orient_polygon`
- `orient_multi_polygon`

## Test

### `orient_polygon`

- Default direction makes a CW exterior CCW

```mbt check
///|
test "orient_polygon - Default makes exterior CCW" {
  let cw_exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (0.0, 1.0),
    (1.0, 1.0),
    (1.0, 0.0),
    (0.0, 0.0),
  ])
  let oriented = orient_polygon(
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
test "orient_polygon - Reversed makes exterior CW" {
  let ccw_exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
    (0.0, 0.0),
  ])
  let oriented = orient_polygon(
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

### `orient_multi_polygon`

- Re-orients every polygon in the collection

```mbt check
///|
test "orient_multi_polygon - re-orients every polygon" {
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
  let oriented = orient_multi_polygon(mp, OrientDirection::Default)
  let actual = match winding_order(oriented.polygons()[0].exterior()) {
    Some(w) => w
    None => abort("expected winding order for non-degenerate exterior")
  }
  @test.assert_eq(actual, WindingOrder::CounterClockwise)
}
```
