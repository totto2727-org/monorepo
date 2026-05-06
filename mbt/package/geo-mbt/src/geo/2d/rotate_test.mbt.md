# rotate.mbt

Geometry rotation. `rotate_geometry_around` rotates around an explicit pivot; `rotate_geometry_around_centroid` rotates around the geometry's centroid (falling back to the origin when no centroid is defined).

## Public API

- `rotate_geometry_around`
- `rotate_geometry_around_centroid`

## Test

### `rotate_geometry_around`

- 180° rotation around the origin sends `(1, 0)` to `(-1, 0)` (up to float round-off)

```mbt check
///|
test "rotate_geometry_around - origin pivot, square 180 deg" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (1.0, 0.0),
    (1.0, 1.0),
    (0.0, 1.0),
  ])
  let polygon = @type.Polygon::Polygon(exterior, [])
  let rotated = rotate_geometry_around(
    @type.Geometry::Polygon(polygon),
    180.0,
    @type.Coord::Coord(0.0, 0.0),
  )
  let p = try! rotated.try_into_polygon()
  let coords = p.exterior().coords()
  // (1, 0) → (-1, 0) up to floating-point round-off.
  assert_true((coords[1].x() - -1.0).abs() < TOLERANCE)
  assert_true(coords[1].y().abs() < TOLERANCE)
}
```

### `rotate_geometry_around_centroid`

- 180° rotation around the centroid leaves the polygon's centroid invariant — verified via `HasCentroid::centroid`

```mbt check
///|
test "rotate_geometry_around_centroid - 180 deg leaves centroid fixed" {
  let exterior = @type.LineString::from_tuples([
    (0.0, 0.0),
    (4.0, 0.0),
    (4.0, 2.0),
    (0.0, 2.0),
  ])
  let g = @type.Geometry::Polygon(@type.Polygon::Polygon(exterior, []))
  let original_centroid = match HasCentroid::centroid(g) {
    Some(p) => p
    None => abort("expected centroid for non-empty polygon")
  }
  let rotated_centroid = match
    HasCentroid::centroid(rotate_geometry_around_centroid(g, 180.0)) {
    Some(p) => p
    None => abort("expected centroid for rotated polygon")
  }
  assert_true((rotated_centroid.x() - original_centroid.x()).abs() < TOLERANCE)
  assert_true((rotated_centroid.y() - original_centroid.y()).abs() < TOLERANCE)
}
```
