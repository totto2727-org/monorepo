# `lines_iter.mbt` — visit every edge / segment in a geometry

## Goal

The edge analogue of `coords_iter.mbt`. Where `coords_*` yields *vertices*, `lines_*` yields the **`Line` segments** that connect consecutive vertices — the geometry's "skeleton".

Used by anything that needs to process geometry **edge-by-edge**: distance from a point to a polygon, segment intersection, ray casting for point-in-polygon, line-clipping, sweep algorithms, etc.

## API surface

| Function                                | Returns         | Description                                                                  |
| --------------------------------------- | --------------- | ---------------------------------------------------------------------------- |
| `lines_of_geometry(g)`                  | `Array[Line]`   | Dispatch over the `Geometry` enum                                            |
| `lines_of_line(l)`                      | `Array[Line]`   | `[l]` — a single-element array (a `Line` is its own only edge)               |
| `lines_of_line_string(ls)`              | `Array[Line]`   | `n−1` segments connecting consecutive coords (delegates to `LineString::lines`) |
| `lines_of_multi_line_string(mls)`       | `Array[Line]`   | All members' lines concatenated, in member order                             |
| `lines_of_polygon(p)`                   | `Array[Line]`   | Exterior ring's edges, then each interior ring's edges                       |
| `lines_of_multi_polygon(mp)`            | `Array[Line]`   | All polygon edges, in member order                                           |
| `lines_of_geometry_collection(gc)`      | `Array[Line]`   | Recurses into each member                                                    |
| `lines_of_rect(r)`                      | `Array[Line]`   | Thin wrapper around `Rect::to_lines` — 4 edges CCW from `min` corner          |
| `lines_of_triangle(t)`                  | `Array[Line]`   | Thin wrapper around `Triangle::to_lines` — 3 edges                           |

For shapes without edges (`Point`, `MultiPoint`, `Coord`), `lines_of_geometry` returns an **empty array** — there are no segments between zero coords.

## What counts as an edge

For a **closed ring** (polygon exterior or interior), the last edge connects the final coord back to the first — i.e. the ring's `n` coords yield `n` edges (`n−1` from the array plus the implicit close). The port relies on the polygon constructor having auto-closed the ring, so `lines_of_polygon` simply walks adjacent coord pairs and the closure is automatic.

For an **open** line string (start ≠ end), `n` coords yield `n−1` edges. There is no implicit "close back to start" segment.

## Examples

```moonbit nocheck
// Open line string of 4 coords → 3 edges
let ls = @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)])
@lib2d.lines_of_line_string(ls).length()         // 3

// Polygon (auto-closed) of 4 corners → 4 edges
let square = @type.Polygon::Polygon(ls, [])
@lib2d.lines_of_polygon(square).length()         // 4 (closing edge included)

// Rect → 4 edges
let r = @type.Rect::Rect(@type.Coord(0.0, 0.0), @type.Coord(1.0, 1.0))
@lib2d.lines_of_rect(r).length()                 // 4

// Point → no edges
let pt = @type.Geometry::Point(@type.Point::Point(3.0, 4.0))
@lib2d.lines_of_geometry(pt).length()            // 0
```

Tests in `lines_iter_test.mbt`:

- `lines_of_line_string yields n-1 segments`
- `lines_of_rect yields 4 edges`
- `lines_of_geometry returns empty for Point`

## Edge ordering

Edges come out in the **same order as the source coords**. For a polygon that means: exterior edges (starting from the exterior's `coords[0] → coords[1]`), then each interior ring in the order they appear in the `interiors` array. This determinism matters when an algorithm wants to pair edges with their indices (e.g. for "report the edge index where the intersection occurred").

For a `MultiPolygon` / `GeometryCollection`, the order is depth-first member-by-member.

## Performance

`O(n)` in total edge count. Eager — allocates one `Array[Line]` of the right size. For very large geometries the lazy alternative `LineString::lines_iter` (and friends) is available on the type itself; the algorithm-layer free functions don't currently provide a `_iter` variant because the typical caller wants random access (e.g. `lines[i]`).

## Related

- `coords_iter.mbt` — vertex-level iteration (one level finer-grained).
- `closest_point.mbt`, `intersects.mbt`, `coordinate_position.mbt` — primary consumers of these per-edge iterators.
- `LineString::lines_iter` — lazy `Iter[Line]` form on the type, when allocation matters.
