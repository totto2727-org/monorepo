# `map_coords.mbt` — apply a function to every coordinate

## Goal

Take a geometry and a per-`Coord` transformation function `(Coord) -> Coord`, and return a **new geometry of the same shape** with every coordinate replaced by the function's output. The structural skeleton (which polygons have which holes, which line strings are inside which collection) is preserved exactly — only the coord values change.

This is the **functor over coords** for the `Geometry` enum. Almost every coordinate-system transformation, projection, or numeric perturbation is one call to `map_coords_in_*`.

## API surface

```moonbit nocheck
pub fn map_coords_in_point(p, f)              -> Point
pub fn map_coords_in_line(l, f)               -> Line
pub fn map_coords_in_line_string(ls, f)       -> LineString
pub fn map_coords_in_polygon(p, f)            -> Polygon
pub fn map_coords_in_multi_point(mp, f)       -> MultiPoint
pub fn map_coords_in_multi_line_string(mls, f) -> MultiLineString
pub fn map_coords_in_multi_polygon(mp, f)     -> MultiPolygon
pub fn map_coords_in_rect(r, f)               -> Rect
pub fn map_coords_in_triangle(t, f)           -> Triangle
pub fn map_coords_in_geometry_collection(gc, f) -> GeometryCollection
pub fn map_coords_in_geometry(g, f)           -> Geometry
```

`f` is `(Coord) -> Coord`. The function is **pure**: it must not mutate any external state (the algorithm doesn't promise any particular call order; you should treat each call as independent).

## Behaviour

Per type:

- **`Point`**: `Point::from_coord(f(p.coord))`
- **`Line`**: new `Line` with `f(start)`, `f(end)`
- **`LineString`**: array of `f(c)` for every coord, wrapped back into a `LineString`
- **`Polygon`**: same on the exterior and each interior ring, then re-construct via `Polygon::Polygon(...)` (which re-runs auto-closure on the transformed rings)
- **`Rect`**: applies `f` to `min` and `max` corners and re-runs the constructor's normalisation, so a transformation that flips orientation produces a sensible `Rect` with `min.x <= max.x` and `min.y <= max.y`
- **`Triangle`**: applies `f` to each of the three vertices
- **Multi / collection types**: recursively map every member and re-wrap

The result has the **same enum variant** as the input. `Geometry::Point(_)` stays `Geometry::Point(_)`, etc.

## Examples

```moonbit nocheck
// Translate a polygon by (10, 5) by composing map_coords_in_polygon with
// a per-coord shift.

///|
let polygon = @type.Polygon::Polygon(
  @type.LineString::from_tuples([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]),
  [],
)

///|
let shifted = @lib2d.map_coords_in_polygon(polygon, fn(c) {
  @type.Coord(c.x() + 10.0, c.y() + 5.0)
})
// shifted's exterior is now [(10, 5), (11, 5), (11, 6), (10, 6), (10, 5)]
```

The dedicated `translate_*` / `rotate_*` / `scale_*` / `skew_*` functions in their own files (`translate.mbt`, `rotate.mbt`, …) are all implemented as one-line wrappers around `map_coords_in_*` — the affine transform builds the closure, then `map_coords` does the walk.

Tests in `map_coords_test.mbt`:

- `map_coords_in_point shifts the coord`
- `map_coords_in_polygon transforms all rings`
- `map_coords_in_geometry roundtrip with identity`

## Functor laws

The free functions satisfy the standard functor laws (informally):

- **Identity**: `map_coords_in_g(g, fn(c) { c }) == g`
- **Composition**: `map_coords_in_g(map_coords_in_g(g, f), h) == map_coords_in_g(g, fn(c) { h(f(c)) })`

The first one is exercised by `map_coords_in_geometry roundtrip with identity` in `map_coords_test.mbt`. The second one is implicit in how the affine-transform combinators chain (e.g. `translate ∘ rotate` is computed as a single composed `(Coord) -> Coord`, not as two separate `map_coords` passes).

## Edge cases

- **Empty geometries** — the transformation is applied to zero coords; the result is the empty geometry of the same shape.
- **`f` produces invalid output** (e.g. NaN) — `map_coords_in_*` does not validate. If `f` violates polygon validity (e.g. collapses two corners onto each other, creating a self-intersecting ring), the output will be structurally a polygon but invalid by the OGC SFA spec. Run `validation.mbt`'s `is_valid` afterwards if downstream code requires it.
- **`f` flips orientation** (e.g. negate `y`) — the polygon's winding order will flip too. Algorithms that depend on a particular winding (notably most boolean ops) should re-orient via `orient_polygon` after the map.

## Performance

`O(n)` calls to `f`. The output array is `Array::makei`-built where size is known up front, or built via spread literal otherwise. No incremental `push` loops — see `coding/mbt-bestpractice.md` §3.12 for why.
