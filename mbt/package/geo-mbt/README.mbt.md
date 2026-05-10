# @totto2727/geo-mbt

MoonBit port of [georust/geo](https://georust.org/): 2D planar geospatial primitives and algorithms.

Scope: 2D planar geometry only, `f64` (`Double`) coordinates only. 3D, geodesic / spherical computations, boolean operations, and triangulation are out of scope for the initial port — see `docs/roadmap/geo-mbt/` for the full roadmap.

## Modules

- `src/geo/2d/type/` — geometry primitives (Coord, Point, Line, LineString, Polygon, etc.)
- `src/geo/2d/` — algorithms (area, bounding rect, distance, contains, etc.)
- `src/robust/` — robust predicates (orient2d, incircle) ported from the [`robust`](https://github.com/georust/robust) crate

## Geometry types (15 total)

`Coord`, `Point`, `MultiPoint`, `Line`, `LineString`, `MultiLineString`, `Polygon`, `MultiPolygon`, `Rect`, `Triangle`, `GeometryCollection`, `Geometry` (10-variant enum).

## Algorithms

| Category               | Functions                                                                                                             |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Iteration              | `coords_of_*`, `lines_of_*`, `map_coords_in_*`, `exterior_coords_of_*`                                                |
| Bounding & area        | `bounding_rect_of_*`, `signed_area_of_*` / `unsigned_area_of_*`, `dimensions_of_*`, `is_empty_of_geometry`            |
| Robust kernels         | `@robust.orient2d`, `@robust.incircle`, `Orientation`, `orient(p, q, r)`                                              |
| Vector ops             | `magnitude`, `magnitude_squared`, `left`, `right`, `dot_product`, `wedge_product`, `try_normalize`, `is_finite`       |
| Distance               | `euclidean_distance_*`, `euclidean_length_*`, `euclidean_bearing`, `euclidean_destination`                            |
| Topology               | `coord_position_for_*` (CoordPos), `intersects_*`                                                                     |
| Containment            | `contains_*`, `within_*`, `covers_*`                                                                                  |
| Centroid / extremes    | `centroid_*`, `extremes_of_*`, `winding_order`, `is_convex`, `orient_polygon`                                         |
| Affine                 | `AffineTransform`, `translate_*`, `rotate_geometry_around*`, `scale_geometry_around`, `skew_geometry*`                |
| Hulls                  | `convex_hull_of_*` (Andrew's monotone chain)                                                                          |
| Closest / intersection | `closest_point_on_*` (Closest), `line_intersection` (LineIntersection), `line_locate_point`, `line_interpolate_point` |
| Simplification         | `simplify_*` (RDP), `simplify_vw_*`, `chaikin_smoothing`, `remove_repeated_points_*`                                  |
| Distance metrics       | `frechet_distance`, `hausdorff_distance_*`, `densify_*`                                                               |
| Validation             | `validation_problems`, `is_valid` (returns `Array[ValidationProblem]`)                                                |

## Example

```moonbit
fn example() -> Unit {
  let polygon = @type.Polygon::new(
    @type.LineString::from_tuples([
      (0.0, 0.0),
      (10.0, 0.0),
      (10.0, 10.0),
      (0.0, 10.0),
    ]),
    [],
  )
  let area = @lib2d.unsigned_area_of_polygon(polygon)
  let centroid = @lib2d.centroid_polygon(polygon).unwrap()
  let bbox = @lib2d.bounding_rect_of_polygon(polygon).unwrap()
  println("area=\{area}, centroid=\{centroid}, bbox=\{bbox}")
}
```

## API correspondence

See [`api-correspondence.md`](./api-correspondence.md) for a per-item table mapping every type, trait, function, test, and benchmark in this port back to its upstream Rust counterpart in `geo` / `geo-types` / `robust` / `rstar`, including the exact upstream commit hash referenced for each library.

## Roadmap

See `docs/roadmap/geo-mbt/` for the multi-cycle porting plan (15 milestones). Out-of-scope items follow this priority order:

1. Spatial Index (R\*-tree)
2. Trait abstraction (constraint-only — generics over numeric types and 3D verified impossible in MoonBit)
3. Boolean Operations (Union / Intersection / Difference / XOR / Buffer)
4. Rust fuzz tests / benchmarks
