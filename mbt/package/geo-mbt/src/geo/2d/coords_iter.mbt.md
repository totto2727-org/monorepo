# `coords_iter.mbt` — visit every coordinate in a geometry

## Goal

Walk **every coordinate** that a geometry contains, in a deterministic order, and either count them or collect them into an array. This is the moral equivalent of `Iterable<Coord>` for the `Geometry` enum.

Useful as the first step in nearly every algorithm that needs to **inspect or transform every vertex** without caring about the geometry's shape — for example bounding-rect computation, validation, coord rounding, or coordinate-system transformations.

## API surface

| Function                                 | Returns        | Description                                                         |
| ---------------------------------------- | -------------- | ------------------------------------------------------------------- |
| `coords_count(g)`                        | `Int`          | Total number of coords in `g`                                       |
| `coords_of_geometry(g)`                  | `Array[Coord]` | All coords, dispatched per variant                                  |
| `coords_of_{point,line,line_string,...}` | `Array[Coord]` | Per-shape — see table below                                         |
| `coords_of_geometry_collection(gc)`      | `Array[Coord]` | Walks each member and concatenates                                  |
| `exterior_coords_of_polygon(p)`          | `Array[Coord]` | Just the exterior ring, **not** the interiors (holes)               |
| `exterior_coords_of_multi_polygon(mp)`   | `Array[Coord]` | Just the exterior rings of each member                              |
| `exterior_coords_of_geometry(g)`         | `Array[Coord]` | Dispatch — for non-polygonal types this equals `coords_of_geometry` |

There's also a port-wide trait `CoordsCarrier { coords(self) -> Array[Coord] }` with impls for every `geo/2d/type` so callers can write generic code over "anything with coords".

## Per-shape coordinate sources

| Shape                | Coords yielded                                                                              |
| -------------------- | ------------------------------------------------------------------------------------------- |
| `Coord` itself       | `[c]`                                                                                       |
| `Point`              | `[p.coord]`                                                                                 |
| `Line`               | `[l.start, l.end]`                                                                          |
| `LineString`         | `ls.coords` (in array order)                                                                |
| `MultiPoint`         | each `Point` flattened                                                                      |
| `MultiLineString`    | each `LineString`'s coords concatenated, in member order                                    |
| `Polygon`            | exterior ring's coords, then each interior ring's coords (in order)                         |
| `MultiPolygon`       | exterior + interiors of each polygon, in member order                                       |
| `GeometryCollection` | every member geometry's coords, in member order                                             |
| `Rect`               | the 5 ring coords (4 corners + closing repeat) — same as `to_polygon().exterior().coords()` |
| `Triangle`           | `[v0, v1, v2]` — note: **not** closed (no repeat of `v0`)                                   |

## `coords_count` vs `coords_of_*().length()`

`coords_count` is implemented to **avoid materialising the array** when you only need the count. For deeply nested `GeometryCollection`s this saves an `O(n)` allocation. If you need the coords themselves anyway, just call `coords_of_*` and use `.length()` on the result.

## Why `exterior_coords_of_*` exists

When you're computing something that should ignore holes (e.g. a polygon's outline length, or its convex hull, or its bounding box of the _outer_ ring only), interior rings are noise. `exterior_coords_of_*` skips them.

For non-polygonal types `exterior_coords_of_*` is identical to `coords_of_*` because there are no interior rings — but the dispatch still routes through the right thing for `Polygon` / `MultiPolygon` / `Geometry`.

## Examples

```moonbit nocheck
let polygon = @type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0)]),
  [
    @type.LineString::from_tuples([(2.0, 2.0), (4.0, 2.0), (4.0, 4.0), (2.0, 4.0)]),
  ],
)

@lib2d.coords_of_polygon(polygon).length()
//   exterior 5 (4 corners + closing) + interior 5 = 10

@lib2d.exterior_coords_of_polygon(polygon).length()   // 5

@lib2d.coords_count(@type.Geometry::Polygon(polygon)) // 10
```

A `GeometryCollection` walks each member:

```moonbit nocheck
let gc = @type.GeometryCollection([
  @type.Geometry::Point(@type.Point::Point(1.0, 2.0)),
  @type.Geometry::Line(
    @type.Line::Line(@type.Coord(0.0, 0.0), @type.Coord(5.0, 5.0)),
  ),
])
@lib2d.coords_of_geometry_collection(gc).length()   // 1 + 2 = 3
```

Tests in `coords_iter_test.mbt`:

- `coords_of_point yields one coord`
- `coords_of_multi_point preserves order`
- `coords_of_polygon walks exterior then interiors`
- `coords_count via Geometry dispatch`

Plus the bench `bench: coords_of_polygon n=100` (`coords_iter_bench_test.mbt`).

## Performance

`O(n)` in the total coord count. Eager — produces an `Array[Coord]` of the right size in one allocation (uses `Array::makei` for the homogeneous shapes; falls back to `[..a, ..b]` spread concatenation for composites).

If you only need to iterate (not collect), prefer `Array.iter()` on the returned array, or use the per-shape direct accessors (`polygon.exterior().coords()`, etc.) to avoid the dispatch cost.
