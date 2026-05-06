# `orient.mbt` — enforce polygon ring winding order

## Goal

Take a polygon and **reorient** its exterior + interior rings so they follow a desired convention:

- `OrientDirection::Default` — exterior **CCW**, interiors **CW** (OGC SFA / GeoJSON convention).
- `OrientDirection::Reversed` — exterior **CW**, interiors **CCW** (Shapefile-style).

If a ring already has the right orientation, it's left untouched. Otherwise, it's reversed via `reverse_line_string`.

This is what you call right before handing a polygon to an algorithm that assumes a particular winding (e.g. `bool_ops.mbt`'s clipping, GIS export to a format with strict winding requirements).

## API surface

```moonbit nocheck
pub(all) enum OrientDirection {
  Default     // exterior CCW, interiors CW
  Reversed    // exterior CW, interiors CCW
}

pub fn orient_polygon(p : Polygon, dir : OrientDirection) -> Polygon
pub fn orient_multi_polygon(mp : MultiPolygon, dir : OrientDirection) -> MultiPolygon
```

## Algorithm

```
for the exterior ring:
  cur = winding_order(exterior)
  if cur == None or cur matches the target for `dir`:
    keep
  otherwise:
    exterior = reverse_line_string(exterior)

for each interior ring:
  apply the OPPOSITE target winding (interiors invert exterior)
  same logic: query, reverse if needed.

return new Polygon(reoriented_exterior, reoriented_interiors)
```

The "opposite target" rule is what enforces the **always-opposite** convention between exterior and interior rings:

| `dir`      | Exterior target | Interior target |
| ---------- | --------------- | --------------- |
| `Default`  | CCW             | CW              |
| `Reversed` | CW              | CCW             |

## Why ring orientation matters

OGC SFA / GeoJSON / GeoPackage / WKT all specify polygon ring orientation, and many algorithms in `geo`/`geo-mbt` assume one of these conventions:

- **Signed area** (`signed_area_of_polygon`) reports a positive value for the standard convention. Algorithms that branch on `sign(area)` need consistent input winding.
- **Boolean ops** (Sutherland-Hodgman in `bool_ops.mbt`, future full booleans) require exterior CCW for "inside is to the left of each edge".
- **Coordinate position** algorithms (ray-casting in `coordinate_position.mbt`) work for both windings, but their output may flip between Inside and Outside if a polygon's exterior is the wrong way round.

When data comes from a heterogeneous source (GeoJSON, shapefile, custom serialised), running `orient_polygon` first puts everything on the same convention.

## Examples

```moonbit nocheck
// CW exterior — needs flipping for the default convention
let cw_poly = @type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (0.0, 10.0), (10.0, 10.0), (10.0, 0.0)]),  // CW
  [],
)
@lib2d.winding_order(cw_poly.exterior())          // Some(Clockwise)

let oriented = @lib2d.orient_polygon(cw_poly, @lib2d.OrientDirection::Default)
@lib2d.winding_order(oriented.exterior())         // Some(CounterClockwise)
```

For a polygon with a hole:

```moonbit nocheck
///|
let polygon_with_inverted_hole = @type.Polygon::Polygon(
  // exterior already CCW
  @type.LineString::from_tuples([
    (0.0, 0.0),
    (10.0, 0.0),
    (10.0, 10.0),
    (0.0, 10.0),
  ]),
  [
    // interior also CCW — but Default convention wants CW interiors!
    @type.LineString::from_tuples([
      (2.0, 2.0),
      (4.0, 2.0),
      (4.0, 4.0),
      (2.0, 4.0),
    ]),
  ],
)

///|
let fixed = @lib2d.orient_polygon(
  polygon_with_inverted_hole,
  @lib2d.OrientDirection::Default,
)
//   exterior unchanged (already CCW)
//   interior reversed to CW
```

Tests in `orient_test.mbt`:

- `orient_polygon: makes exterior CCW by default`

Property test (`property_test.mbt`):

- `property: orient_polygon is idempotent` — running it twice in a row should give the same result as running it once. This catches sign-flip bugs.

## Edge cases

- **Degenerate ring** (zero signed area) — `winding_order` returns `None`, so no reversal is attempted. The ring stays as-is.
- **Open ring** (start ≠ end) — the polygon constructor would have closed it; `orient_polygon` works on the closed ring.
- **Polygon without holes** — only the exterior is processed. The interior loop is a no-op.

## Performance

- One `winding_order` call per ring (`O(n_ring)`).
- Optional `reverse_line_string` per ring (also `O(n_ring)`).
- Total: `O(total coords)` across all rings.

A polygon that's already correctly oriented incurs only the winding queries and no reversals — almost free.

## Related

- `winding_order.mbt` — the underlying CCW/CW classifier.
- `area.mbt` — `signed_area_of_polygon` reports positive for default-oriented polygons (same convention).
- `bool_ops.mbt` — clipping requires Default-oriented inputs.
