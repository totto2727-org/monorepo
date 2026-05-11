# @totto2727/geo-mbt

MoonBit port of [georust/geo](https://georust.org/): 2D planar + geographic geospatial primitives and algorithms.

Scope: 2D geometry only, `f64` (`Double`) coordinates only. 3D remains out of scope. See `docs/roadmap/geo-mbt/` for the full roadmap (Phase 2 complete, ms-01〜ms-33 landed; ms-34 v0.2.0 release prep in progress).

## Modules

- `src/geo/2d/type/` — geometry primitives (Coord, Point, Line, LineString, Polygon, etc.)
- `src/geo/2d/` — algorithms (area, bounding rect, distance, contains, triangulation, etc.)
- `src/robust/` — robust predicates (orient2d, incircle) ported from the [`robust`](https://github.com/georust/robust) crate
- `src/rtree/` — R\*-tree spatial index (bulk load, insert, remove, locate, nearest neighbors, iter, drain)

## Geometry types (15 total)

`Coord`, `Point`, `MultiPoint`, `Line`, `LineString`, `MultiLineString`, `Polygon`, `MultiPolygon`, `Rect`, `Triangle`, `GeometryCollection`, `Geometry` (10-variant enum).

## Algorithms

| Category               | Functions                                                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Iteration              | `coords_of_*`, `lines_of_*`, `map_coords_in_*`, `exterior_coords_of_*`                                                        |
| Bounding & area        | `bounding_rect_of_*`, `signed_area_of_*` / `unsigned_area_of_*`, `dimensions_of_*`, `is_empty_of_geometry`                    |
| Robust kernels         | `@robust.orient2d`, `@robust.incircle`, `Orientation`, `orient(p, q, r)`                                                      |
| Vector ops             | `magnitude`, `magnitude_squared`, `left`, `right`, `dot_product`, `wedge_product`, `try_normalize`, `is_finite`               |
| Distance               | `euclidean_distance_*`, `euclidean_length_*`, `euclidean_bearing`, `euclidean_destination`                                    |
| Geographic distances   | `HaversineMeasure` / `Vincenty` / `RhumbMeasure` — bearing, destination, distance, length                                     |
| Topology               | `coord_position_for_*` (CoordPos), `intersects_*`                                                                             |
| Containment            | `contains_*`, `within_*`, `covers_*`                                                                                          |
| DE-9IM                 | `relate`, `IntersectionMatrix`, 8 boolean predicates (contains/covers/within/intersects/disjoint/touches/crosses/overlaps)    |
| Centroid / extremes    | `centroid_*`, `extremes_of_*`, `winding_order`, `is_convex`, `orient_polygon`                                                 |
| Affine                 | `AffineTransform`, `translate_*`, `rotate_geometry_around*`, `scale_geometry_around`, `skew_geometry*`, inverse, compose_many |
| Hulls                  | `convex_hull_of_*` (Andrew's monotone chain), `k_nearest_concave_hull`, `delaunay_concave_hull`                               |
| Closest / intersection | `closest_point_on_*` (Closest), `line_intersection` (LineIntersection), `line_locate_point`, `line_interpolate_point`         |
| Simplification         | `simplify_*` (RDP), `simplify_vw_*`, `chaikin_smoothing`, `remove_repeated_points_*`                                          |
| Distance metrics       | `frechet_distance`, `hausdorff_distance_*`, `densify_*`, `densify_haversine_*`, `cross_track_distance`                        |
| Predicate traits       | `Contains`, `Covers`, `Intersects`, `Within` — implemented for 11 geometry types                                              |
| Validation             | `validation_problems`, `is_valid` (RingRole / CoordIndex / GeometryIndex payloads)                                            |
| Sweep                  | `segment_intersections`, `has_segment_intersection`                                                                           |
| Boolean ops            | `polygon_intersection`, `polygon_union`, `polygon_difference`, `polygon_xor`, `unary_union`, `clip_line_string`               |
| Buffer                 | `buffer_point`, `buffer_line_string`, `buffer_polygon` (Round / Square / Flat caps, Round / Miter / Bevel joins)              |
| Stitch / repair        | `stitch_line_strings`, `repair_polygon`                                                                                       |
| Triangulation          | `earcut` (polygon triangulation), `delaunay_triangulation` (Bowyer-Watson)                                                    |
| Voronoi                | `voronoi_diagram`, `voronoi_vertices` (Delaunay dual)                                                                         |
| Clustering             | `dbscan` (DBSCAN with R\*-tree), `dbscan_outliers`, `kmeans`                                                                  |
| Indexed                | `indexed_contains_polygons`, `indexed_intersecting_polygons`, `indexed_nearest_point` (R\*-tree backed)                       |
| Spherical area         | `chamberlain_duquette_signed_area_*`                                                                                          |

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
}
```

## Status

- **Phase 1** (ms-01〜ms-15): complete — 411 tests
- **Phase 2** (ms-16〜ms-33): complete — 521 tests
- **ms-34** (v0.2.0 release prep): in progress
