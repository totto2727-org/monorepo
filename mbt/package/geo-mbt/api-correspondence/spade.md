# 7. `spade` ↔ `src/geo/2d/delaunay.mbt` (+ `voronoi.mbt`, `concave_hull.mbt`)

> **Note**: Phase 2 ms-27 delivers a Delaunay triangulation with the same
> public _return shape_ (a list of triangles indexing into the original
> vertex array) but via the simpler **Bowyer-Watson incremental algorithm**
> instead of spade's flip-based DCEL. ms-28 (Voronoi) derives its diagram
> from this Delaunay output. The spade clone below is kept as reference
> for a future direct port if its richer feature set (constraints,
> conforming Delaunay, persistent handles, intrusive iteration) becomes
> needed.

### 7.1 Spade public API

| Rust module / item                                                  | MoonBit port                                                                                                 | Status | Notes                                                                                                                           |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ------ | ------------------------------------------------------------------------------------------------------------------------------- |
| `DelaunayTriangulation<V, …>`                                       | `pub fn delaunay_triangulation(Array[Coord]) -> Array[DelaunayTriangle]?`                                    | 🟡     | Returns plain index-triple list, not a triangulation handle                                                                     |
| `ConstrainedDelaunayTriangulation<V, …>` (CDT)                      | —                                                                                                            | ⏳     | Edge constraints / conforming Delaunay not yet supported                                                                        |
| `Triangulation` trait (insert / locate / hull / etc.)               | —                                                                                                            | ⛔     | Port has no handle / DCEL surface                                                                                               |
| `Point2`, `HasPosition`, `SpadeNum`, `TriangulationExt`             | —                                                                                                            | ⛔     | Hard-coded `@type.Coord`; no generic point machinery                                                                            |
| `iterators::*` (all-faces / vertices / edges / hull iters)          | —                                                                                                            | ⏳     | The port surfaces the full triangle list directly via `delaunay_triangles_to_geometries`; per-element iteration not yet exposed |
| `voronoi::*` (Voronoi diagram derived from Delaunay)                | `voronoi_diagram`, `voronoi_vertices` + `VoronoiEdge` (Phase 2 ms-28)                                        | 🟡     | Edge list only; polygonal cells / vertex dedup deferred                                                                         |
| `delaunay_core::math::{circumcenter, side_query, …}`                | (`@robust.incircle` for in-circle; non-robust `orient2d` for CCW; ad-hoc circumcenter math in `voronoi.mbt`) | ✅     | Robustness path uses Shewchuk's non-adaptive `incircle`; near-cocircular inputs may misclassify until an adaptive variant lands |
| `delaunay_core::dcel::*` (DCEL impl)                                | —                                                                                                            | ⛔     | Bowyer-Watson uses a flat `Array[InternalTri]` instead                                                                          |
| `spade_with_spatial_index`                                          | —                                                                                                            | ⏳     | Spatial location currently O(n²); spade's locate-via-walking-edges deferred                                                     |
| Bulk-insert / hint location / lazy hull / persistent vertex handles | —                                                                                                            | ⏳     |                                                                                                                                 |

### 7.2 Concave-hull (ms-29 — Delaunay-based variant)

`delaunay_concave_hull(Array[Coord], Double) -> LineString?` uses the
Delaunay triangulation above with a `concavity × mean_edge_length`
trim threshold. The k-NN concave hull variant (`k_nearest_concave_hull`,
Moreira-Santos 2007) is independent of spade — see §2 row.

---
