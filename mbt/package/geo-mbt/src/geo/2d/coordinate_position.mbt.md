# `coordinate_position.mbt` — where is a coord, relative to a geometry?

## Goal

Classify a single `Coord` as **inside**, **on the boundary**, or **outside** a 2D geometry. The result is the building block for `contains`, `within`, `covers`, and the eventual DE-9IM `relate`.

## API surface

```moonbit nocheck
pub(all) enum CoordPos {
  OnBoundary
  Inside
  Outside
}

pub fn coord_position_for_line(c, l)            -> CoordPos
pub fn coord_position_for_line_string(c, ls)    -> CoordPos
pub fn coord_position_for_polygon(c, p)         -> CoordPos
pub fn coord_position_for_multi_polygon(c, mp)  -> CoordPos
pub fn coord_position_for_rect(c, r)            -> CoordPos
pub fn coord_position_for_triangle(c, t)        -> CoordPos
pub fn coord_position_for_geometry(c, g)        -> CoordPos
pub fn coord_on_line(c, l)                      -> Bool       // shortcut: c is on the closed segment l
```

## What "boundary" / "inside" / "outside" mean per shape

| Shape         | Boundary                                              | Inside                                                                    | Outside                                |
| ------------- | ----------------------------------------------------- | ------------------------------------------------------------------------- | -------------------------------------- |
| `Line`        | The two endpoints                                     | The open segment between them                                             | Anywhere else                          |
| `LineString`  | The two extreme endpoints (or empty if closed ring)   | Any other point that lies on a segment                                    | Anywhere else                          |
| `Polygon`     | Every coord that lies on the exterior or any interior ring | Coord strictly inside exterior **and** outside every interior ring         | Outside exterior, or inside any hole   |
| `MultiPolygon`| Boundary of any member                                | Inside any member's interior                                              | Outside every member                   |
| `Rect`        | The 4 edges                                           | Strictly inside the rect                                                  | Outside                                |
| `Triangle`    | The 3 edges                                           | Strictly inside                                                           | Outside                                |

OGC SFA terms: the "interior" is the open set; the "boundary" is the topological boundary; the "exterior" of a geometry is the complement of (interior ∪ boundary).

## Algorithm — line / line string / boundary cases

A coord is on a line segment `(a, b)` iff:

1. `orient(a, b, c) == Collinear` (uses the robust `kernel.mbt`).
2. The coord lies between `a` and `b` along the line, i.e. its parametric `t` falls in `[0, 1]` (`coord_on_line` checks both via `min`/`max` of the components).

For a line string, the coord is on the boundary iff it equals the first or last coord and the line string is open. Otherwise, walk every segment with the `coord_on_line` test — if any segment hits, the coord is `Inside` (the interior of a 1-D geometry is its open arc minus its endpoints).

## Algorithm — polygon

This is the classic **point-in-polygon** problem. The port uses the **ray-casting** method:

```
1. Trivial reject: if c is outside the polygon's bounding rect, return Outside.
2. Boundary check: if c lies on any ring edge (exterior or interior),
   return OnBoundary. (Robust segment containment via kernel.mbt's orient.)
3. Ray casting:
   a. Shoot a horizontal ray from c to +∞.
   b. Count how many edges of all rings the ray crosses.
   c. Odd count ⇒ Inside; even count ⇒ Outside.
```

The ray-casting "counting" is implemented carefully to handle edge cases:

- **Ray passes exactly through a vertex** — could double-count. Resolved by counting "below-to-above" crossings only (strict inequality on one side).
- **Coord lies exactly on an edge** — caught by step 2 before reaching the ray-casting step.
- **Horizontal edge collinear with the ray** — its endpoints are tested separately as part of the adjacent edges; the horizontal edge contributes 0 crossings.

For a polygon with **holes**, a coord is `Inside` only if it's inside the exterior **and** outside every interior ring — this falls out of the parity rule because a coord inside a hole has its ray crossing the hole's boundary an extra two times (entering + exiting), keeping the parity unchanged from "inside exterior" → "outside hole-region of exterior".

## Algorithm — rect / triangle

`Rect` is a special case: a coord is on the boundary if it lies on any of the 4 edges, inside if `min.x < c.x < max.x` and `min.y < c.y < max.y`, outside otherwise. The bbox-vs-coord comparison is `O(1)`.

`Triangle` is also a special case but uses three orientation checks: a coord is inside iff it's on the same side of all three edges (all `orient` results agree). On any edge ⇒ boundary. Otherwise outside. Robust by virtue of using `kernel.orient`.

## Examples

```moonbit nocheck
let polygon = @type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0)]),
  [],
)

@lib2d.coord_position_for_polygon(@type.Coord(5.0, 5.0), polygon)   // Inside
@lib2d.coord_position_for_polygon(@type.Coord(0.0, 5.0), polygon)   // OnBoundary (on left edge)
@lib2d.coord_position_for_polygon(@type.Coord(20.0, 5.0), polygon)  // Outside
```

With a hole:

```moonbit nocheck
let with_hole = @type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0)]),
  [
    @type.LineString::from_tuples([(3.0, 3.0), (7.0, 3.0), (7.0, 7.0), (3.0, 7.0)]),
  ],
)
@lib2d.coord_position_for_polygon(@type.Coord(5.0, 5.0), with_hole)   // Outside (in hole)
@lib2d.coord_position_for_polygon(@type.Coord(2.0, 2.0), with_hole)   // Inside
```

Tests in `coordinate_position_test.mbt`:

- `coord_position polygon: inside / boundary / outside`
- `coord_position polygon with hole: inside hole`
- `coord_position rect`
- `coord_on_line endpoints and midpoints`

## Why robust matters here

A coord that's mathematically *exactly* on an edge can fail the boundary check under naive `f64` arithmetic (the orient determinant rounds to a non-zero value), and the ray-casting fallback can then misclassify it. The port uses the robust `orient` everywhere boundary detection happens, which keeps OnBoundary correctly distinguished from the two halfplanes.

## Performance

`O(n)` in total ring length: one bbox check (`O(1)`), one pass over all edges to detect boundary (`O(n)`), and one pass to count ray crossings (`O(n)`). For huge polygons the bbox early-out is the most important optimisation.

## Related

- `contains.mbt`, `covers.mbt`, `within.mbt` — built on top of this; e.g. `contains_polygon_coord = (coord_position_for_polygon == Inside)`.
- `intersects.mbt` — uses ray casting for the coord-polygon intersection case.
- `kernel.mbt` — the robust orient predicate used throughout.
