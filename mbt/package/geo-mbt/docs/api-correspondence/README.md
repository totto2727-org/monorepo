# `@totto2727/geo-mbt` API correspondence

Per-item correspondence between the MoonBit port and its Rust upstreams,
split per upstream library. This directory is the structural counterpart
to the roadmap (which tracks milestone status only); each file enumerates
every type, trait, function, test and benchmark in the port's
corresponding region and maps it back to the upstream Rust item it was
ported from.

Originally a single file at `mbt/package/geo-mbt/api-correspondence.md`;
split per upstream library on 2026-05-11 to make per-library diffs and
per-library navigation easier.

## Per-library files

Directly ported (algorithm / data structure reproduced in MoonBit):

| Library             | File                           | Port section                                                       |
| ------------------- | ------------------------------ | ------------------------------------------------------------------ |
| `geo-types`         | [geo-types.md](./geo-types.md) | `src/geo/2d/type/` (Coord, Point, Line, LineString, Polygon, ...)  |
| `geo` (georust/geo) | [geo.md](./geo.md)             | `src/geo/2d/` (algorithms, traits, property tests, benches)        |
| `robust` (georust)  | [robust.md](./robust.md)       | `src/robust/` (orient2d, incircle, Shewchuk primitives)            |
| `rstar`             | [rstar.md](./rstar.md)         | `src/rtree/` (R-tree spatial index, dynamic ops, nearest / locate) |
| `earcutr`           | [earcutr.md](./earcutr.md)     | `src/geo/2d/earcut.mbt` (Mapbox earcut polygon triangulation)      |

Inspiration-only (algorithm conceptually equivalent, but the port wrote
an alternative implementation from scratch — usually because the upstream
code base is too large or because a simpler classical algorithm matches
the milestone surface):

| Library            | File                                         | Notes                                                          |
| ------------------ | -------------------------------------------- | -------------------------------------------------------------- |
| `i_overlay`        | [i_overlay.md](./i_overlay.md)               | + `iFloat` / `iShape` / `iTree` / `iKeySort` dependency crates |
| `spade`            | [spade.md](./spade.md)                       | Delaunay + Voronoi + Delaunay-based concave hull               |
| `geographiclib-rs` | [geographiclib-rs.md](./geographiclib-rs.md) | Geodesic engine (Karney) deferred                              |
| `num-traits`       | [num-traits.md](./num-traits.md)             | Not used — port hard-codes `Double`                            |

Cross-cutting:

| Topic                    | File                                   |
| ------------------------ | -------------------------------------- |
| Skipped per-type helpers | [retrospective.md](./retrospective.md) |

## Source revisions

> Versions / commit hashes captured against the working trees under
> `~/proj/geo/`. Re-run the listed `git` commands when the upstream
> snapshots are refreshed (see the [Update procedure](#update-procedure) below).

### Directly ported (algorithm / data structure reproduced in MoonBit)

| Library             | Crate version | Branch   | Commit                                     | Date       | Path under `~/proj/geo/`  | Port section                   |
| ------------------- | ------------- | -------- | ------------------------------------------ | ---------- | ------------------------- | ------------------------------ |
| `geo` (georust/geo) | `0.33.1`      | `main`   | `f34ee562db2a843037fb865d354b82a521cd9796` | 2026-04-29 | `georust-geo/geo/`        | [geo.md](./geo.md)             |
| `geo-types`         | `0.7.19`      | `main`   | `f34ee562db2a843037fb865d354b82a521cd9796` | 2026-04-29 | `georust-geo/geo-types/`  | [geo-types.md](./geo-types.md) |
| `geo-traits`        | `0.3.0`       | `main`   | `f34ee562db2a843037fb865d354b82a521cd9796` | 2026-04-29 | `georust-geo/geo-traits/` | (unused — no separate file)    |
| `robust` (georust)  | `1.2.0`       | `main`   | `654f34cb8cdb3ae21bf59ef3472f92652942cd74` | 2025-05-09 | `robust/`                 | [robust.md](./robust.md)       |
| `rstar`             | `0.12.2`      | `master` | `4e510b0b85ec8e6994a03104a5075ae4701d1bfa` | 2026-03-27 | `rstar/rstar/`            | [rstar.md](./rstar.md)         |
| `earcutr`           | `0.5.0`       | `master` | `a201db6b6ec10ec9bb58fd5960242c64b29ab2ba` | 2026-05-04 | `earcutr/`                | [earcutr.md](./earcutr.md)     |

### Inspiration-only (algorithm conceptually equivalent, but the port wrote an alternative implementation from scratch — usually because the upstream code base is too large or because a simpler classical algorithm matches the milestone surface)

| Library            | Crate version | Branch   | Commit                                     | Date       | Path under `~/proj/geo/` | Port section                                 | Alternative used                                                                          |
| ------------------ | ------------- | -------- | ------------------------------------------ | ---------- | ------------------------ | -------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `i_overlay`        | `6.0.0`       | `main`   | `3e9f651b04e887002204eea9478074e593da6711` | 2026-05-02 | `i_overlay/iOverlay/`    | [i_overlay.md](./i_overlay.md)               | Greiner-Hörmann polygon clipping (`src/geo/2d/bool_ops.mbt`)                              |
| `i_float`          | `2.0.0`       | `main`   | `ee70a687cddad989503d5db3dcb8cfa7ee29fd6b` | 2026-05-02 | `iFloat/`                | [i_overlay.md](./i_overlay.md)               | Not used — port stays on raw `Double`                                                     |
| `i_shape`          | `2.0.0`       | `main`   | `5f00a4d3b8a0353edf257980d636bd665aae067c` | 2026-05-02 | `iShape/`                | [i_overlay.md](./i_overlay.md)               | Not used — port reuses `@type.Polygon` / `MultiPolygon`                                   |
| `i_tree`           | `0.18.0`      | `main`   | `ca44173f54d3b971957ba726f5240e9b9b36bb2b` | 2026-03-01 | `iTree/`                 | [i_overlay.md](./i_overlay.md)               | Not used — sweep section currently uses a sorted-array active set                         |
| `i_key_sort`       | (n/a)         | `main`   | `73ea5e42f75439e24bbd2155742d583c91507dee` | 2026-04-24 | `iKeySort/`              | [i_overlay.md](./i_overlay.md)               | Not used — MoonBit `Array::sort` covers the call sites                                    |
| `spade`            | `2.15.1`      | `master` | `c8befc96bbbc1898a89cb19f9f3104a848936374` | 2026-03-24 | `spade/`                 | [spade.md](./spade.md)                       | Bowyer-Watson incremental Delaunay (`src/geo/2d/delaunay.mbt`) — no DCEL, no constraints  |
| `geographiclib-rs` | `0.2.7`       | `main`   | `c5e906d94a4664b5be160eb03f89e76b15cc5ece` | 2026-02-17 | `geographiclib-rs/`      | [geographiclib-rs.md](./geographiclib-rs.md) | Direct ports of `geo` crate's Haversine/Vincenty/Rhumb formula files — no geodesic engine |
| `num-traits`       | `0.2.19`      | `master` | `fbdc29a42db0883f762a9247e8759782543c7297` | 2025-06-17 | `num-traits/`            | [num-traits.md](./num-traits.md)             | Not used — port hard-codes `Double`; no `Float` / `FromPrimitive` abstraction needed      |

Port snapshot:

- Package: `totto2727/geo-mbt` `v0.1.0` (`./moon.mod.json`).
- Last commit affecting the port: `02f281a (2026-05-10)` —
  `fix(bw): satisfy lint rules in formatErrorChain (no-let, isNullish, no-base-to-string)`
  (most recent geo-mbt content commit: `eca00ca (2026-05-10)` — `style: fix markdown table formatting for CI`).

## Status legend

| Symbol | Meaning                                                                          |
| ------ | -------------------------------------------------------------------------------- |
| ✅     | Ported with passing tests                                                        |
| 🟡     | Partial port (subset of variants / overloads — see per-row note)                 |
| ⛔     | Explicit non-goal of the port (see `mbt/package/geo-mbt/CLAUDE.md`)              |
| ⏳     | Not yet ported but in scope (deferred)                                           |
| —      | Not applicable (Rust idiom that has no MoonBit counterpart, e.g. iterator types) |

Scope reminders (from `mbt/package/geo-mbt/CLAUDE.md`, Phase 2 ms-16〜ms-34 complete):

- 2D only — Z coordinate is out of scope.
- `Double` / `f64` only — no generic `CoordNum`.
- Planar Euclidean **and** geographic (spherical / ellipsoidal). Haversine,
  Vincenty, and Rhumb metric spaces are available for distance / length /
  bearing / destination (geo §ms-32 / ms-33). Geodesic (Karney /
  `geographiclib-rs`) remains deferred — see
  [geographiclib-rs.md](./geographiclib-rs.md).
- Boolean ops (Greiner-Hörmann), triangulation (earcut + Delaunay),
  R\*-tree spatial index, DE-9IM relate, and Bentley-Ottmann sweep are
  **available** as of Phase 2.

## Aggregate test / bench counts

Verified with `moon test` (which excludes `@bench.T` blocks from its
count). Bench counts come from `grep -c '@bench\.T' <file>` across each
`*_bench_test.mbt`.

Snapshot after the public-API privatisation pass (2026-05-11): **`Total tests:
520`** across the full `geo-mbt` package — up from the Phase-1 close
baseline of 411 (+109 net). The drop from the immediate-post-PR-review
peak (524) is the four `twice_signed_ring_area` doctest blocks removed
from `area.mbt.md`; the same coverage is retained in
`area_wbtest.mbt` (whitebox), so the underlying primitive is still
exercised four times.
Per-milestone contribution:

| Milestone                              | Cumulative tests | Delta from previous                 |
| -------------------------------------- | ---------------- | ----------------------------------- |
| Phase 1 close                          | 411              | (baseline)                          |
| ms-16 trait + small ⏳                 | 411              | 0                                   |
| ms-17 validation                       | 414              | +3                                  |
| ms-32 geographic                       | 414              | 0                                   |
| ms-33 geographic algos                 | 414              | 0                                   |
| ms-26 earcut                           | 423              | +9                                  |
| ms-19 sweep                            | 434              | +11                                 |
| ms-18 R\*-tree dynamic                 | 447              | +13                                 |
| ms-30 indexed                          | 458              | +11                                 |
| ms-31 clustering                       | 470              | +12                                 |
| ms-20 DE-9IM                           | 479              | +9                                  |
| ms-27 Delaunay                         | 486              | +7                                  |
| ms-28 Voronoi                          | 494              | +8                                  |
| ms-29 concave hull                     | 504              | +10                                 |
| ms-21/22/23 bool ops                   | 524              | +20                                 |
| ms-24/25 buffer/stitch                 | 524              | 0 (in-file doctests not counted)    |
| ms-34 release prep                     | 524              | 0                                   |
| public-API privatisation (post-review) | 520              | −4 (relocated to `area_wbtest.mbt`) |

Doctest migration (`3a4914d` + ms-16〜ms-33) is now complete across
`geo/2d/type/`, `geo/2d/`, and most Phase 2 additions. Bench files keep
the `*_bench_test.mbt` form (15 benches under `geo/2d`, 1 under
`robust`, 4 under `rtree` — **20 total**). Phase 2 milestones did not
add new bench files yet; performance benchmarks for the new algorithms
are a post-v0.2.0 follow-up.

The per-package breakdown is intentionally omitted now that all blackbox
`*_test.mbt` files have been replaced — re-run `moon test` from the
package root to get the current per-package totals if needed.

## Notable changes since the initial port survey

- **Canonical constructor naming**: every type defines `TypeName::TypeName(...)` as its single public ctor. Call sites use the short form `TypeName(...)` or qualified `TypeName::TypeName(...)`. The Rust `::new` style was removed.
- **AffineTransform restructured** into nested structs:
  - `AffineRow { scale, skew, translate }` represents one matrix row.
  - `AffineTransform { row_x: AffineRow, row_y: AffineRow }` replaces the previous flat `{ a, b, xoff, d, e, yoff }` layout.
  - `AffineTransform::transform[T : MapCoords](self, x : T) -> T` is the single generic dispatcher (replaces the four `transform_geometry` / `transform_polygon` / `transform_line_string` / `transform_point` methods).
- **Trait surface expanded**: **24 traits in total** as of Phase 2 close (21 algorithm-layer — including the 4 predicate traits `Contains` / `Covers` / `Intersects` / `Within` added in ms-16 plus `Orient` and `RemoveRepeatedPoints` introduced alongside the per-type-helper privatisation pass, each colocated with its impls in the corresponding algorithm file; 3 type-shape traits `IsEmpty` / `IsClosed` / `HasLength` in `geo/2d/type/traits.mbt`). Per-type free functions like `coords_of_polygon`, `signed_area_of_*`, `bounding_rect_of_*`, `contains_polygon_*`, `covers_polygon_*`, `intersects_*`, `orient_polygon` / `orient_multi_polygon`, `remove_repeated_points_*`, `chamberlain_duquette_*_polygon`, `translate_polygon` / `translate_point`, `twice_signed_ring_area` etc. are now **package-private** — external callers should use the corresponding trait method (`CoordsCarrier::coords(p)` / `Contains::contains(a, g)` / `Orient::orient(p, dir)` / `RemoveRepeatedPoints::remove_repeated_points(g)` etc.) or the unified `*_geometry` entry point.
- **Private-helper convention**: the `<op>_<shape>` functions remain as `fn` (no `pub`) inside their algorithm file so they can be exercised by `*_wbtest.mbt` whitebox tests; the trait impl right next to them in the same file delegates to them.
- **Trait colocation**: each algorithm-layer trait + impls live in the same file as the per-type helpers (e.g. `HasArea` in `area.mbt`, `Bounded` in `bounding_rect.mbt`, `LinesCarrier` in `lines_iter.mbt`, `MapCoords` in `map_coords.mbt`). The previously-monolithic `traits.mbt` was dismantled.
- **`Triangle::to_array` removed** — `coords_of_triangle` / `CoordsCarrier::coords` covers the same shape.
- **`signed_area_of_triangle_robust` removed** — was a one-line wrapper around `@robust.orient2d`; callers should call the latter directly.
- **`is_empty_of_geometry` removed** — replaced by the `IsEmpty` trait impl for `Geometry` (in `type/geometry.mbt`); callable via dot-syntax (`g.is_empty()`) thanks to the same-file impl rule, or via explicit `IsEmpty::is_empty(g)`.
- **`Default` derive added** on `LineString` / `MultiPoint` / `MultiLineString` / `MultiPolygon` / `GeometryCollection` — `Default::default()` returns the canonical empty value (equivalent to the existing `<type>::empty()` factory). `Coord` and `Point` already had `derive(Default)`.
- **`Point` is a named-field struct** (`{ coord: Coord }`) instead of the previous newtype-tuple `Point(Coord)`.
- **Immutable rewrites**: `LineString::close(&mut self)` → `LineString::closed(Self) -> Self`; `Polygon::interiors_push(&mut self, _)` → `Polygon::pushed_interior(Self, LineString) -> Self`; `Polygon` constructor no longer mutates input `LineString`s (uses `LineString::closed` to clone-only-when-needed).
- **Lazy iterator pairs**: `LineString` provides eager + lazy pairs side-by-side as independent implementations: `points` / `points_iter`, `lines` / `lines_iter`, `rev_lines` / `rev_lines_iter`.
- **`Geometry::try_into_<variant>`**: 10 raise-based extractors (one per variant) + `MismatchedGeometry` suberror with `expected~` / `found~` fields. The MoonBit equivalent of upstream's `TryFrom<Geometry<T>>` impls.
- **Test files split per source** (post-Step-5 alignment): `affine_test.mbt` → `affine_transform_test.mbt`; `closest_test.mbt` → 4 files (`closest_point`, `line_intersection`, `line_locate_point`, `line_interpolate_point`); `containment_test.mbt` → `contains` + `covers`; `distance_metrics_test.mbt` → `frechet_distance` + `hausdorff_distance` + `densify`; `iteration_test.mbt` → `coords_iter` + `lines_iter` (since merged) + `map_coords`; `measure_test.mbt` → `bounding_rect` + `area` + `dimensions`; `shape_test.mbt` → `centroid` + `winding_order` + `is_convex` + `orient` + `extremes`; `topology_test.mbt` → `coordinate_position` + `intersects`; `vector_distance_test.mbt` → `vector_ops` + `euclidean`; `simplify_test.mbt` carved off `simplify_vw` + `chaikin_smoothing` + `remove_repeated_points`; `bench_test.mbt` split into 13 per-source bench files; `robust_test.mbt` split into `orient2d_test.mbt` + `incircle_test.mbt`.

## Update procedure

When upstream snapshots are refreshed:

1. `git -C ~/proj/geo/<lib> log -1 --format='%H %ai %s'` to capture the
   new commit + date.
2. `grep -E '^(name|version|edition)' ~/proj/geo/<lib>/Cargo.toml` for
   the crate version.
3. Update the appropriate table under "## Source revisions" above. The
   two tables are:
   - **Directly ported** — for libraries whose algorithm / data
     structure is reproduced in MoonBit (currently `geo`, `geo-types`,
     `geo-traits`, `robust`, `rstar`, `earcutr`).
   - **Inspiration-only** — for libraries cloned as reference but where
     the port wrote an alternative implementation (currently
     `i_overlay` + iShape-Rust crates, `spade`, `geographiclib-rs`,
     `num-traits`).
4. Re-diff the relevant module(s) under `~/proj/geo/<lib>/src/` against
   the port's `pkg.generated.mbti` (run `moon info` first if `.mbti` is
   stale) and refresh the Status column in the corresponding per-library
   file for any items whose upstream signature changed.
5. After refreshing the upstream snapshots, run `moon test` and update
   the per-milestone test-count table in [Aggregate test / bench
   counts](#aggregate-test--bench-counts) above if the totals shift.
