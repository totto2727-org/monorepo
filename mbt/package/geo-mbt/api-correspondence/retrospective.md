# Retrospective — per-type helpers held over from the privatisation pass

The PR #125 review pass (2026-05-11) drove a policy:

> Per-type は原則公開せず、可能な限り trait もしくは統合関数レベルでのみ公開する。
> ただし boolean のように出力が `Self` ではない／出力が入力の型によって変化するものは
> 作業後に報告だけして一旦スキップする。

This file captures the audit findings whose changes were **skipped on
purpose** — they need a fresh trait / unified-API design (or a new
upstream-style polymorphic shape) before they can stop exposing per-type
free functions. They are tracked here so they don't quietly drift back
into the "fix later" pile.

## Skipped because output type varies by input type

These functions have public per-type entry points whose return type is
genuinely heterogeneous (e.g. `Polygon → MultiPolygon`, `Line → Coord?`,
`LineString → Point?`). Wrapping them behind a single trait would either
require GATs / associated types we don't have or would force callers to
pattern-match on a `Geometry` variant that has nothing to do with the
operation they want to perform. The right move is a small trait family
per algorithm, not collapsing them under one umbrella.

| File                                                                                                    | Public per-type helpers                                                                                                                                          | Output shape                                                                                                           | Trait design needed                                                                                                        |
| ------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| [`mbt/package/geo-mbt/src/geo/2d/bool_ops.mbt`](../src/geo/2d/bool_ops.mbt)                             | `clip_line_string`, `intersection_polygon_rect`, `intersection_sutherland_hodgman`                                                                               | `LineString → MultiLineString`, `Polygon × Rect → MultiPolygon`                                                        | A `BooleanOps` family (one trait per op: `Intersection` / `Union` / `Difference` / `Xor`) à la upstream `geo::BooleanOps`. |
| [`mbt/package/geo-mbt/src/geo/2d/buffer.mbt`](../src/geo/2d/buffer.mbt)                                 | `buffer_point`, `buffer_line_string`, `buffer_polygon`, `stitch_line_strings`, `repair_polygon`                                                                  | `Point / LineString / Polygon → MultiPolygon`                                                                          | A `Buffer` trait taking a `BufferOptions` parameter and producing `MultiPolygon`. Upstream `geo::Buffer` matches.          |
| [`mbt/package/geo-mbt/src/geo/2d/densify_haversine.mbt`](../src/geo/2d/densify_haversine.mbt)           | `densify_haversine_line`, `densify_haversine_line_string`, `densify_haversine_polygon`, `densify_haversine_multi_line_string`, `densify_haversine_multi_polygon` | Returns `Self` per input type, but co-exists with the planar `Densify` trait (LineString / Polygon) defined elsewhere. | Either extend the existing planar `Densify` to take a metric-space parameter, or introduce a geographic-flavoured trait.   |
| [`mbt/package/geo-mbt/src/geo/2d/line_interpolate_point.mbt`](../src/geo/2d/line_interpolate_point.mbt) | `line_interpolate_point`, `line_string_interpolate_point`                                                                                                        | `Line → Coord?`, `LineString → Point?`                                                                                 | `InterpolatePoint` trait à la upstream `geo::line_measures::InterpolatePoint`.                                             |
| [`mbt/package/geo-mbt/src/geo/2d/line_locate_point.mbt`](../src/geo/2d/line_locate_point.mbt)           | `line_locate_point`, `line_string_locate_point`                                                                                                                  | `Line × Coord → Double?` / `LineString × Coord → Double?` (return Self-independent but per-shape)                      | `LineLocatePoint` trait keyed on the line carrier (Line vs LineString).                                                    |

## Skipped because the upstream trait is missing in the port

These return `Bool` or `Double` (so output type does **not** vary by
input) and are real per-type pairwise APIs. The cleanest cleanup is to
port the matching upstream trait first; the per-type helpers can stay
`pub` until that trait lands so we don't have to ship two follow-ups.

| File                                                                                                | Public per-type helpers                                                                                                                                                                                                                                        | Upstream trait to port                                                                    |
| --------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| [`mbt/package/geo-mbt/src/geo/2d/euclidean.mbt`](../src/geo/2d/euclidean.mbt)                       | `euclidean_distance_coords`, `euclidean_distance_points`, `euclidean_distance_squared_coords`, `euclidean_distance_coord_to_line`, `euclidean_distance_point_to_line`, `euclidean_distance_coord_to_line_string`, `euclidean_bearing`, `euclidean_destination` | `geo::line_measures::Distance<Euclidean>` family (`Distance` + metric-space `Euclidean`). |
| [`mbt/package/geo-mbt/src/geo/2d/hausdorff_distance.mbt`](../src/geo/2d/hausdorff_distance.mbt)     | `hausdorff_distance_coords`, `hausdorff_distance_line_strings`, etc.                                                                                                                                                                                           | `geo::HausdorffDistance` (planar-Euclidean variant).                                      |
| [`mbt/package/geo-mbt/src/geo/2d/frechet_distance.mbt`](../src/geo/2d/frechet_distance.mbt)         | `frechet_distance_line_strings`                                                                                                                                                                                                                                | `geo::FrechetDistance`.                                                                   |
| [`mbt/package/geo-mbt/src/geo/2d/cross_track_distance.mbt`](../src/geo/2d/cross_track_distance.mbt) | `cross_track_distance`                                                                                                                                                                                                                                         | `geo::CrossTrackDistance` (haversine-flavoured).                                          |

## Skipped because the per-type helper is a canonical entry point

These look per-type but are the canonical public surface — no broader
trait equivalent exists in upstream `geo` either. They stay `pub`
intentionally.

| File                                                                                              | Public function                                                                       | Why it stays `pub`                                                                                                                                                                        |
| ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`mbt/package/geo-mbt/src/geo/2d/extremes.mbt`](../src/geo/2d/extremes.mbt)                       | `extremes_of_coords`                                                                  | Input `Array[Coord]` is itself the canonical shape; the `HasExtremes` trait already wraps it for the geometry variants.                                                                   |
| [`mbt/package/geo-mbt/src/geo/2d/indexed.mbt`](../src/geo/2d/indexed.mbt)                         | `indexed_contains_polygons`, `indexed_nearest_point`, `indexed_intersecting_polygons` | Closure-returning idiom — these don't have a Self-or-trait equivalent, the closure shape is the API.                                                                                      |
| [`mbt/package/geo-mbt/src/geo/2d/coordinate_position.mbt`](../src/geo/2d/coordinate_position.mbt) | `coord_on_line`                                                                       | Internal predicate that is also consumed by `intersects` / `relate` — kept `pub` because callers need it on the segment-only fast path before deciding to construct a `Geometry` wrapper. |

## How to retire this list

For each "trait design needed" row above, the cleanup recipe is the same
as ms-16 / Phase-2 review pass:

1. Add the upstream-shaped trait (e.g. `BooleanOps`, `InterpolatePoint`,
   `Distance<Euclidean>`).
2. Move the existing per-type bodies to package-private (`fn`) under the
   trait impls in the same file.
3. Migrate `.mbt.md` doctests / `_bench_test.mbt` benches to the trait
   surface; move whitebox-only checks into `*_wbtest.mbt`.
4. Update the corresponding per-library file under this directory plus
   `README.md` (trait inventory + aggregate counts).

Each entry should be tracked as its own roadmap item (likely a Phase 3
follow-up milestone) so this retrospective stays an _index_ of pending
work, not a place where the work itself lives.
