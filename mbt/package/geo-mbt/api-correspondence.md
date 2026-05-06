# `@totto2727/geo-mbt` API correspondence

Per-item correspondence table between the MoonBit port and its Rust upstreams.

This file is the structural counterpart to the roadmap (which tracks
milestone status only). It enumerates every type, trait, function, test
and benchmark in the port and maps it back to the upstream Rust item it
was ported from.

## Source revisions

> Versions / commit hashes captured against the working trees under
> `~/proj/geo/`. Re-run the listed `git` commands when the upstream
> snapshots are refreshed.

| Library               | Crate version | Branch   | Commit                                     | Date       | Path under `~/proj/geo/`  |
| --------------------- | ------------- | -------- | ------------------------------------------ | ---------- | ------------------------- |
| `geo` (georust/geo)   | `0.33.1`      | `main`   | `f34ee562db2a843037fb865d354b82a521cd9796` | 2026-04-29 | `georust-geo/geo/`        |
| `geo-types`           | `0.7.19`      | `main`   | `f34ee562db2a843037fb865d354b82a521cd9796` | 2026-04-29 | `georust-geo/geo-types/`  |
| `geo-traits` (unused) | `0.3.0`       | `main`   | `f34ee562db2a843037fb865d354b82a521cd9796` | 2026-04-29 | `georust-geo/geo-traits/` |
| `robust` (georust)    | `1.2.0`       | `main`   | `654f34cb8cdb3ae21bf59ef3472f92652942cd74` | 2025-05-09 | `robust/`                 |
| `rstar`               | `0.12.2`      | `master` | `4e510b0b85ec8e6994a03104a5075ae4701d1bfa` | 2026-03-27 | `rstar/rstar/`            |

Port snapshot:

- Package: `totto2727/geo-mbt` `v0.1.0` (`./moon.mod.json`).
- Last commit affecting the port: `b86fb95 (2026-05-06)` —
  `style(geo-mbt): apply vp check --fix formatting to roadmap + readme + moon.mod.json`.

## Status legend

| Symbol | Meaning                                                                          |
| ------ | -------------------------------------------------------------------------------- |
| ✅     | Ported with passing tests                                                        |
| 🟡     | Partial port (subset of variants / overloads — see per-row note)                 |
| ⛔     | Explicit non-goal of the port (see `./CLAUDE.md`)                                |
| ⏳     | Not yet ported but in scope (deferred)                                           |
| —      | Not applicable (Rust idiom that has no MoonBit counterpart, e.g. iterator types) |

Scope reminders (from `./CLAUDE.md`):

- 2D only — Z coordinate is out of scope.
- `Double` / `f64` only — no generic `CoordNum`.
- Planar Euclidean only — geodesic / Vincenty / Haversine / Rhumb are out of scope.
- DE-9IM `relate`, Bentley-Ottmann `sweep`, full boolean operations, triangulation,
  R-tree-as-spatial-index are deferred. (Note: `src/rtree/` was added post-scope as
  a standalone bulk-load index — see the rstar section below.)

---

## 1. `geo-types` ↔ `src/geo/2d/type/`

Port package: `totto2727/geo-mbt/geo/2d/type` (`src/geo/2d/type/pkg.generated.mbti`).

Upstream Rust types are generic over `T: CoordNum`; the port collapses
the parameter to `Double`. Mutable Rust accessors (`set_x`, `coords_mut`,
`exterior_mut`, etc.) are intentionally dropped — MoonBit values are
treated as immutable.

### 1.1 `Coord<T>` ↔ `type/coord.mbt`

| Rust upstream item                       | MoonBit port                                                   | Status | Notes                                          |
| ---------------------------------------- | -------------------------------------------------------------- | ------ | ---------------------------------------------- |
| `pub struct Coord<T> { x, y }`           | `pub struct Coord { x: Double, y: Double }`                    | ✅     | Derives `Default`, `Eq`, `Hash`, `Debug`       |
| `Coord::zero() -> Self`                  | `Coord::zero() -> Self`                                        | ✅     |                                                |
| `Coord::x_y(&self) -> (T, T)`            | `Coord::x_y(Self) -> (Double, Double)`                         | ✅     |                                                |
| `From<(T, T)>`, `From<[T; 2]>`           | `Coord::from_tuple`, `Coord::from_array`                       | ✅     | Rust uses traits, port uses named ctors        |
| `coord! { x, y }` macro                  | `Coord(x, y)`                                                  | ✅     | Port's positional ctor                         |
| `impl Add/Sub/Neg/Mul<T>/Div<T>`         | `impl Add for Coord`, `Sub`, `Neg`; `Coord::mul`, `Coord::div` | ✅     | Scalar ops as methods, vector ops as traits    |
| `Coord::dot/cross_prod` (via algorithms) | `Coord::dot`, `Coord::cross`                                   | ✅     | `cross` = wedge product (2D)                   |
| —                                        | `Coord::is_zero`, `Coord::x`, `Coord::y`                       | ✅     | Accessors added for ergonomic field-less style |
| `set_x`, `set_y`, `x_mut`, `y_mut`       | —                                                              | ⛔     | Immutable port                                 |

Tests: `type/coord_test.mbt` — 13 cases covering ctors, accessors,
`zero`, `from_tuple`/`from_array` round-trips, `Neg`/`Add`/`Sub`,
scalar `mul`/`div`, `dot`, `cross`, equality, and `Default`.

### 1.2 `Point<T>` ↔ `type/point.mbt`

| Rust upstream item                                             | MoonBit port                                    | Status | Notes                                    |
| -------------------------------------------------------------- | ----------------------------------------------- | ------ | ---------------------------------------- |
| `pub struct Point<T>(pub Coord<T>)`                            | `pub struct Point(Coord)`                       | ✅     |                                          |
| `Point::new(x, y)`                                             | `Point::new(Double, Double)`                    | ✅     |                                          |
| `Point::x()`, `y()`, `x_y()`                                   | `Point::x`, `y`, `x_y`                          | ✅     |                                          |
| `Point::dot(self, Self) -> T`                                  | `Point::dot(Self, Self) -> Double`              | ✅     |                                          |
| `Point::cross_prod(self, Self, Self) -> T`                     | `Point::cross_prod(Self, Self, Self) -> Double` | ✅     |                                          |
| `From<Coord<T>>`, `From<(T, T)>`                               | `Point::from_coord`, `Point::from_tuple`        | ✅     |                                          |
| `set_x`, `set_y`, `x_mut`, `y_mut`                             | `Point::with_x`, `Point::with_y`                | ✅     | Replaced with immutable "wither" pattern |
| `lng`, `lat`, `set_lng`, `set_lat`, `to_degrees`, `to_radians` | —                                               | ⛔     | Geographic — out of scope                |
| `impl Add/Sub/Neg/Mul/Div`                                     | `impl Add/Sub/Neg`, `Point::mul`, `Point::div`  | ✅     |                                          |
| —                                                              | `Point::coord(Self) -> Coord`                   | ✅     | Inverse of `from_coord`                  |

Tests: `type/point_test.mbt` — 10 cases including ctor, `from_coord`
round-trip, `with_x`/`with_y`, `dot`, `cross_prod`, `Neg`, `Add`,
`Sub`, scalar `mul`/`div`.

### 1.3 `Line<T>` ↔ `type/line.mbt`

| Rust upstream item                               | MoonBit port                                            | Status | Notes                                                                                                                                                                                                                                |
| ------------------------------------------------ | ------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `pub struct Line<T> { start, end }`              | `pub struct Line { start: Coord, end: Coord }`          | ✅     |                                                                                                                                                                                                                                      |
| `Line::new<C: Into<Coord<T>>>(start, end)`       | `Line::new(Coord, Coord) -> Self`                       | ✅     |                                                                                                                                                                                                                                      |
| `Line::delta()`, `dx()`, `dy()`                  | `Line::delta`, `dx`, `dy`                               | ✅     |                                                                                                                                                                                                                                      |
| `Line::slope()`, `determinant()`                 | `Line::slope`, `determinant`                            | ✅     |                                                                                                                                                                                                                                      |
| `Line::start_point()`, `end_point()`, `points()` | `Line::start_point`, `end_point`, `points`              | ✅     |                                                                                                                                                                                                                                      |
| —                                                | `Line::start`, `Line::end`                              | ✅     | Pair-wise getters returning `Coord`                                                                                                                                                                                                  |
| —                                                | `Line::from_tuples((Double, Double), (Double, Double))` | ✅     | Mirrors `LineString::from_tuples`                                                                                                                                                                                                    |
| —                                                | `Line::reverse(Self) -> Line`                           | ✅     | Independent helper (not in Rust upstream); returns a new `Line` with `start` / `end` swapped. Note: `LineString::rev_lines{,_iter}` does NOT use this — it constructs reversed segments directly to avoid the round-trip allocation. |

Tests: `type/line_test.mbt` — 10 cases (ctor, dx/dy/delta, `slope`
direction-independence, `determinant` sign flip on reversal,
`points`/`start_point`/`end_point`, `reverse` swaps start/end, `reverse`
involutive, `reverse` flips determinant sign).

### 1.4 `LineString<T>` ↔ `type/line_string.mbt`

| Rust upstream item                                                                                              | MoonBit port                                                                            | Status | Notes                                                                                                                                                                                                                                   |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pub struct LineString<T>(pub Vec<Coord<T>>)`                                                                   | `pub struct LineString { coords: Array[Coord] }`                                        | ✅     |                                                                                                                                                                                                                                         |
| `LineString::new(Vec<Coord<T>>)`                                                                                | `LineString::new(Array[Coord])`                                                         | ✅     |                                                                                                                                                                                                                                         |
| `LineString::empty()`                                                                                           | `LineString::empty`                                                                     | ✅     | Equivalent to `LineString([])`. Mirrors Rust upstream as a named factory.                                                                                                                                                               |
| `coords()`                                                                                                      | `LineString::coords`                                                                    | ✅     | Returns the backing `Array[Coord]` (eager). MoonBit `Array` is itself iterable via `.iter()`.                                                                                                                                           |
| `coords_mut()`                                                                                                  | —                                                                                       | 🟡     | Mutable accessor intentionally dropped — MoonBit values are treated as immutable.                                                                                                                                                       |
| `points()`                                                                                                      | `LineString::points`                                                                    | ✅     | Returns `Array[Point]` (eager); each `Coord` wrapped via `Point::from_coord`.                                                                                                                                                           |
| `points_iter()`                                                                                                 | `LineString::points_iter`                                                               | ✅     | Returns `Iter[Point]` (lazy); each `Coord` wrapped on demand via `Point::from_coord`.                                                                                                                                                   |
| `into_inner()`, `into_points()`                                                                                 | —                                                                                       | —      | Rust-specific consumption pattern                                                                                                                                                                                                       |
| `lines()` — yields each `Line` segment between consecutive coords, in array order                               | `LineString::lines` (eager `Array[Line]`), `LineString::lines_iter` (lazy `Iter[Line]`) | ✅     | Same orientation and ordering as upstream. Eager + lazy provided side-by-side as **independent** implementations (no `iter→array` conversion overhead); use `_iter` when chaining `take` / `filter` etc.                                |
| `rev_lines()` — same segments as `lines()` but in reverse order **and** with each `Line` reversed (end → start) | `LineString::rev_lines` (eager), `LineString::rev_lines_iter` (lazy)                    | ✅     | Same reversed-order + swapped-endpoint semantics as upstream. Eager + lazy as independent implementations.                                                                                                                              |
| `triangles()` — yields a `Triangle` from every 3 consecutive coords (sliding window)                            | —                                                                                       | ⏳     | This is the strip-triangle iterator used internally by Visvalingam–Whyatt — **not** a general triangulation (earcut/Delaunay are out of scope ⛔). Port inlines the same loop inside `simplify_vw_line_string` rather than exposing it. |
| `close(&mut self)`                                                                                              | `LineString::close(Self) -> Unit`                                                       | ✅     |                                                                                                                                                                                                                                         |
| `is_closed()`, `num_coords()`                                                                                   | `LineString::is_closed`, `LineString::length`                                           | ✅     |                                                                                                                                                                                                                                         |
| —                                                                                                               | `LineString::is_empty`, `LineString::from_tuples`                                       | ✅     |                                                                                                                                                                                                                                         |

Tests: `type/line_string_test.mbt` — 19 cases (`from_tuples` / length,
empty, `LineString::empty` ↔ `LineString([])` parity, `is_closed`,
`lines`, in-place `close`, `points` eager, `points` empty, `points_iter`
collected = `points()`, `points_iter` short-circuit with `take`,
`rev_lines` reversed order with swapped endpoints, `rev_lines` empty /
single-coord, `rev_lines` ↔ `lines` mirror, `lines_iter` collected =
`lines()`, `lines_iter` empty / single-coord, `lines_iter` short-circuit
with `take`, `rev_lines_iter` collected = `rev_lines()`, `rev_lines_iter`
empty / single-coord, `rev_lines_iter` short-circuit with `take`).

### 1.5 `Polygon<T>` ↔ `type/polygon.mbt`

| Rust upstream item                                               | MoonBit port                                                                | Status | Notes                            |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------- | ------ | -------------------------------- |
| `pub struct Polygon<T> { exterior, interiors }`                  | `pub struct Polygon { exterior: LineString, interiors: Array[LineString] }` | ✅     | Auto-closes rings                |
| `Polygon::new(exterior, interiors)`                              | `Polygon::new(LineString, Array[LineString])`                               | ✅     |                                  |
| `exterior()`, `interiors()`, `into_inner()`                      | `Polygon::exterior`, `Polygon::interiors`                                   | ✅     |                                  |
| `exterior_mut`, `try_exterior_mut`, `interiors_mut`, `try_*_mut` | —                                                                           | ⛔     | Immutable port                   |
| `interiors_push`                                                 | —                                                                           | ⏳     | Not yet                          |
| `num_rings`, `num_interior_rings`                                | `Polygon::num_interiors`                                                    | 🟡     | `num_rings = num_interiors + 1`  |
| `is_convex(&self)`                                               | (free fn `is_convex` on `LineString`)                                       | 🟡     | Lives in algorithm layer instead |
| `Polygon::empty()`                                               | —                                                                           | ⏳     |                                  |

Tests: `type/polygon_test.mbt` — 3 cases (auto-closes exterior, auto-closes
interior rings, already-closed exterior preserved).

### 1.6 `Rect<T>` ↔ `type/rect.mbt`

| Rust upstream item                              | MoonBit port                          | Status | Notes                                     |
| ----------------------------------------------- | ------------------------------------- | ------ | ----------------------------------------- |
| `pub struct Rect<T> { min, max }`               | `pub struct Rect { min, max: Coord }` | ✅     |                                           |
| `Rect::new(c1, c2)` (normalises corners)        | `Rect::new(Coord, Coord)`             | ✅     | Same normalisation                        |
| `Rect::try_new` + `InvalidRectCoordinatesError` | —                                     | ⛔     | Validation handled at higher layer        |
| `min()`, `max()`, `set_min`, `set_max`          | `Rect::min`, `Rect::max`              | 🟡     | Setters dropped                           |
| `width`, `height`, `center`                     | `Rect::width`, `height`, `center`     | ✅     |                                           |
| `to_polygon`, `to_lines`                        | `Rect::to_polygon` + `lines_of_rect`  | 🟡     | `to_lines` lives in `lines_iter`          |
| `split_x`, `split_y`                            | —                                     | ⏳     |                                           |
| —                                               | `Rect::area`                          | ✅     | Convenience wrapper around `width*height` |

Tests: `type/rect_test.mbt` — 5 cases (corner normalisation, width/height,
center, area, `to_polygon` closed-ring shape).

### 1.7 `Triangle<T>` ↔ `type/triangle.mbt`

| Rust upstream item                   | MoonBit port                                   | Status | Notes                                |
| ------------------------------------ | ---------------------------------------------- | ------ | ------------------------------------ |
| `pub struct Triangle<T>(C, C, C)`    | `pub struct Triangle { v0, v1, v2 }`           | ✅     | Named instead of tuple struct        |
| `Triangle::new(v1, v2, v3)`          | `Triangle::new(Coord, Coord, Coord)`           | ✅     | Port indexes from 0 (`v0`/`v1`/`v2`) |
| `unchecked_winding`                  | —                                              | ⏳     |                                      |
| `v1`, `v2`, `v3`                     | `v0`, `v1`, `v2`                               | ✅     | Different naming                     |
| `to_array`, `to_lines`, `to_polygon` | `Triangle::to_array`, `to_lines`, `to_polygon` | ✅     |                                      |

Tests: `type/triangle_test.mbt` — 4 cases (ctor + accessors, `to_array`,
`to_lines` returns 3 segments, `to_polygon` is closed 4-coord ring).

### 1.8 `MultiPoint<T>` ↔ `type/multi_point.mbt`

A heterogeneous collection (newtype-`Vec`) of `Point`s. WKT-equivalent of `MULTIPOINT`.

| Rust upstream item                                       | MoonBit port                                       | Status | Notes                                                             |
| -------------------------------------------------------- | -------------------------------------------------- | ------ | ----------------------------------------------------------------- |
| `pub struct MultiPoint<T>(pub Vec<Point<T>>)`            | `pub struct MultiPoint { points: Array[Point] }`   | ✅     | Newtype-`Vec` collapsed into named field                          |
| `MultiPoint::new(value: Vec<Point<T>>)`                  | `MultiPoint::new(Array[Point]) -> Self`            | ✅     |                                                                   |
| `MultiPoint::empty()`                                    | `MultiPoint::empty() -> Self`                      | ✅     |                                                                   |
| `len()` / `is_empty()`                                   | `MultiPoint::length`, `MultiPoint::is_empty`       | ✅     | Renamed `len` → `length` to match other port collections          |
| `iter()` / `iter_mut()`                                  | `MultiPoint::points(Self) -> Array[Point]`         | 🟡     | Returns the backing array directly — no separate iterator types   |
| `IntoIterator` / `FromIterator` / `IntoParallelIterator` | —                                                  | —      | Rust trait scaffolding; users iterate the returned `Array[Point]` |
| `Index<I>` / `IndexMut<I>`                               | —                                                  | —      | Use `mp.points()[i]` instead                                      |
| `From<Point<T>>` / `From<Vec<Point<T>>>`                 | —                                                  | ⏳     | Could add as ergonomic helpers                                    |
| —                                                        | `MultiPoint::from_tuples(Array[(Double, Double)])` | ✅     | Port-only convenience matching `LineString::from_tuples`          |

Tests (in `type/multi_point_test.mbt`): `MultiPoint::from_tuples`, `MultiPoint empty`, `MultiPoint::empty`.

### 1.9 `MultiLineString<T>` ↔ `type/multi_line_string.mbt`

A collection of `LineString`s. Considered _simple_ when all elements are simple and only intersect at endpoints (port doesn't enforce simplicity at construction).

| Rust upstream item                                      | MoonBit port                                                     | Status | Notes                                                                     |
| ------------------------------------------------------- | ---------------------------------------------------------------- | ------ | ------------------------------------------------------------------------- |
| `pub struct MultiLineString<T>(pub Vec<LineString<T>>)` | `pub struct MultiLineString { line_strings: Array[LineString] }` | ✅     |                                                                           |
| `MultiLineString::new(value: Vec<LineString<T>>)`       | `MultiLineString::new(Array[LineString]) -> Self`                | ✅     |                                                                           |
| `MultiLineString::empty()`                              | `MultiLineString::empty() -> Self`                               | ✅     |                                                                           |
| `is_closed(&self) -> bool`                              | `MultiLineString::is_closed(Self) -> Bool`                       | ✅     | Empty collection counts as closed (matches upstream)                      |
| `iter()` / `iter_mut()`                                 | `MultiLineString::line_strings(Self) -> Array[LineString]`       | 🟡     | Direct backing array; `is_empty` and `length` exposed as separate methods |
| (no upstream equivalent)                                | `MultiLineString::length`, `MultiLineString::is_empty`           | ✅     | Convenience accessors                                                     |
| `IntoIterator` / `FromIterator` / `From<LineString>`    | —                                                                | —      | Rust trait scaffolding                                                    |
| `Index<I>` / `IndexMut<I>`                              | —                                                                | —      |                                                                           |

Tests (in `type/multi_line_string_test.mbt`): `MultiLineString length`, `is_closed: empty is vacuously closed`, `is_closed: all components closed -> true`, `is_closed: any open component -> false`, `is_closed: single closed / single open`, `MultiLineString::empty`.

### 1.10 `MultiPolygon<T>` ↔ `type/multi_polygon.mbt`

A collection of `Polygon`s.

| Rust upstream item                                   | MoonBit port                                           | Status | Notes                                          |
| ---------------------------------------------------- | ------------------------------------------------------ | ------ | ---------------------------------------------- |
| `pub struct MultiPolygon<T>(pub Vec<Polygon<T>>)`    | `pub struct MultiPolygon { polygons: Array[Polygon] }` | ✅     |                                                |
| `MultiPolygon::new(value: Vec<Polygon<T>>)`          | `MultiPolygon::new(Array[Polygon]) -> Self`            | ✅     |                                                |
| `MultiPolygon::empty()`                              | `MultiPolygon::empty() -> Self`                        | ✅     |                                                |
| `iter()` / `iter_mut()`                              | `MultiPolygon::polygons(Self) -> Array[Polygon]`       | 🟡     | Direct backing array                           |
| (no upstream equivalent)                             | `MultiPolygon::length`, `MultiPolygon::is_empty`       | ✅     |                                                |
| `IntoIterator` / `FromIterator` / `From<Polygon>`    | —                                                      | —      |                                                |
| `Index<I>` / `IndexMut<I>`                           | —                                                      | —      |                                                |
| `impl RTreeObject` (via `impl_rstar_multi_polygon!`) | —                                                      | ⛔     | Spatial-index integration is out of port scope |

Tests (in `type/multi_polygon_test.mbt`): `MultiPolygon basic`, `MultiPolygon::empty`.

### 1.11 `GeometryCollection<T>` ↔ `type/geometry_collection.mbt`

A heterogeneous collection of `Geometry` values (the WKT/GeoJSON `GEOMETRYCOLLECTION`).

| Rust upstream item                                                      | MoonBit port                                                    | Status | Notes                                                          |
| ----------------------------------------------------------------------- | --------------------------------------------------------------- | ------ | -------------------------------------------------------------- |
| `pub struct GeometryCollection<T>(pub Vec<Geometry<T>>)`                | `pub struct GeometryCollection { geometries: Array[Geometry] }` | ✅     |                                                                |
| `GeometryCollection::new() -> Self` (no-arg, returns empty)             | `GeometryCollection::empty()`                                   | 🟡     | Port uses `empty()` to avoid `new()` ambiguity with array-form |
| `GeometryCollection::new_from(value: Vec<Geometry<T>>)`                 | `GeometryCollection::new(Array[Geometry]) -> Self`              | ✅     | Port consolidates `new_from` under the canonical `new(_)` name |
| `GeometryCollection::empty()`                                           | `GeometryCollection::empty()`                                   | ✅     |                                                                |
| `len()` / `is_empty()`                                                  | `GeometryCollection::length`, `GeometryCollection::is_empty`    | ✅     |                                                                |
| `iter()` / `iter_mut()`                                                 | `GeometryCollection::geometries(Self) -> Array[Geometry]`       | 🟡     |                                                                |
| `IntoIteratorHelper`, `IterHelper`, `IterMutHelper` (custom iter types) | —                                                               | —      | Rust-specific iterator scaffolding, not needed in MoonBit      |
| `IntoIterator` / `FromIterator`                                         | —                                                               | —      |                                                                |
| `Default::default() == empty()`                                         | (port `derive(Eq, Debug)` only)                                 | ⏳     | `Default` derive not enabled                                   |

Tests (in `type/geometry_collection_test.mbt`): `GeometryCollection holds heterogeneous geometries`, `GeometryCollection::empty`.

### 1.12 `Geometry<T>` enum ↔ `type/geometry.mbt`

| Rust upstream variants                                                                                                        | MoonBit port variants | Status | Notes                         |
| ----------------------------------------------------------------------------------------------------------------------------- | --------------------- | ------ | ----------------------------- |
| `Geometry::{Point, Line, LineString, Polygon, MultiPoint, MultiLineString, MultiPolygon, GeometryCollection, Rect, Triangle}` | identical 10 variants | ✅     |                               |
| `into_point/line/...` extractors                                                                                              | —                     | ⏳     | Pattern matching used instead |

---

## 2. `geo` algorithms ↔ `src/geo/2d/`

Port package: `totto2727/geo-mbt/geo/2d` (`src/geo/2d/pkg.generated.mbti`).

Rust uses extension traits dispatched via blanket impls (e.g. `Area for
Polygon<T>`); the port mostly exposes free functions named `<op>_<shape>`
plus a small number of MoonBit traits where the abstraction is genuinely
useful (`Bounded`, `CoordsCarrier`, `HasArea`, `HasCentroid`, `HasLength`).

### 2.1 Trait-shaped APIs (port-side traits)

| Port trait      | Defined in (port)   | Members                            | Implementing types                                                                                                                              | Mirrors upstream         |
| --------------- | ------------------- | ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| `Bounded`       | `bounding_rect.mbt` | `bbox(Self) -> Rect?`              | `Geometry`, `GeometryCollection`, `Line`, `LineString`, `MultiLineString`, `MultiPoint`, `MultiPolygon`, `Point`, `Polygon`, `Rect`, `Triangle` | `BoundingRect`           |
| `CoordsCarrier` | `coords_iter.mbt`   | `coords(Self) -> Array[Coord]`     | (same 11 types as `Bounded`)                                                                                                                    | `CoordsIter`             |
| `HasArea`       | `area.mbt`          | `signed_area`, `unsigned_area`     | `Geometry`, `MultiPolygon`, `Polygon`, `Rect`, `Triangle`                                                                                       | `Area`                   |
| `HasCentroid`   | `centroid.mbt`      | `centroid(Self) -> Point?`         | `Geometry`, `LineString`, `MultiPolygon`, `Polygon`                                                                                             | `Centroid`               |
| `HasLength`     | `euclidean.mbt`     | `euclidean_length(Self) -> Double` | `Line`, `LineString`, `MultiLineString`                                                                                                         | `Length` for `Euclidean` |

Tests: `traits_test.mbt` — 6 cases covering each trait dispatch, plus a
generic-constraint usage example.

### 2.2 `geo::algorithm::*` ↔ port free functions / methods

| Upstream module / item                                                                                                                                                                                                                                                                                                                                                              | Port item                                                                                                                                                                                                                | Test file                                        | Bench (geo/2d/bench_test.mbt)               | Status                                                           |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------ | ------------------------------------------- | ---------------------------------------------------------------- |
| `affine_ops::AffineTransform::new/identity/translate/scale/rotate/skew`                                                                                                                                                                                                                                                                                                             | `AffineTransform::new/identity/translate_xy/scale_xy/rotate_origin/skew_origin`                                                                                                                                          | `affine_test.mbt`                                | "affine transform translate+rotate compose" | ✅                                                               |
| `affine_ops::AffineTransform::compose/apply`                                                                                                                                                                                                                                                                                                                                        | `AffineTransform::compose/apply`                                                                                                                                                                                         | `affine_test.mbt`                                | (compose covered)                           | ✅                                                               |
| `AffineTransform::a/b/d/e/xoff/yoff` accessors                                                                                                                                                                                                                                                                                                                                      | (struct fields are public)                                                                                                                                                                                               | —                                                |                                             | ✅                                                               |
| `AffineTransform::scaled/translated/rotated/skewed/compose_many/inverse/is_identity`                                                                                                                                                                                                                                                                                                | —                                                                                                                                                                                                                        | —                                                |                                             | ⏳                                                               |
| `affine_ops::AffineOps::affine_transform`                                                                                                                                                                                                                                                                                                                                           | `affine_transform_{point, line_string, polygon, geometry}`                                                                                                                                                               | `affine_test.mbt`                                |                                             | ✅                                                               |
| `area::Area::{signed_area, unsigned_area}`                                                                                                                                                                                                                                                                                                                                          | `signed_area_of_{geometry, multi_polygon, polygon, rect, triangle}` + `unsigned_area_of_*`                                                                                                                               | `measure_test.mbt`                               | "signed_area_of_polygon n=100"              | ✅                                                               |
| `area::twice_signed_ring_area` (private)                                                                                                                                                                                                                                                                                                                                            | `twice_signed_ring_area`                                                                                                                                                                                                 | (used by area tests)                             |                                             | ✅                                                               |
| `area::signed_area::Area for Triangle (robust)`                                                                                                                                                                                                                                                                                                                                     | `signed_area_of_triangle_robust(Coord, Coord, Coord)`                                                                                                                                                                    | `kernel_test.mbt`                                |                                             | ✅                                                               |
| `bounding_rect::BoundingRect::bounding_rect`                                                                                                                                                                                                                                                                                                                                        | `bounding_rect_of_{coord, point, line, line_string, polygon, multi_*, rect, triangle, geometry, geometry_collection}`                                                                                                    | `measure_test.mbt`                               | "bounding_rect_of_line_string n=100"        | ✅                                                               |
| `centroid::Centroid::centroid`                                                                                                                                                                                                                                                                                                                                                      | `centroid_{geometry, line_string, polygon, multi_polygon}`                                                                                                                                                               | `shape_test.mbt`, `property_test.mbt`            | "centroid_polygon n=100"                    | ✅                                                               |
| `chaikin_smoothing::ChaikinSmoothing::chaikin_smoothing`                                                                                                                                                                                                                                                                                                                            | `chaikin_smoothing(LineString, Int)`                                                                                                                                                                                     | `simplify_test.mbt`                              | "chaikin_smoothing 3 iterations"            | ✅                                                               |
| `closest_point::ClosestPoint`                                                                                                                                                                                                                                                                                                                                                       | `closest_point_on_{line, line_string}` + `Closest` enum (`Intersection`, `SinglePoint`, `Indeterminate`)                                                                                                                 | `closest_test.mbt`                               |                                             | ✅                                                               |
| `contains::Contains` (10 impls)                                                                                                                                                                                                                                                                                                                                                     | `contains_{polygon_point, polygon_coord, polygon_line, polygon_line_string, polygon_polygon, multi_polygon_coord, rect_coord, rect_rect, geometry}`                                                                      | `containment_test.mbt`                           |                                             | ✅                                                               |
| `contains_properly::ContainsProperly`                                                                                                                                                                                                                                                                                                                                               | —                                                                                                                                                                                                                        | —                                                |                                             | ⏳                                                               |
| `convex_hull::ConvexHull` (graham + qhull)                                                                                                                                                                                                                                                                                                                                          | `convex_hull_of_{geometry, line_string, multi_point, polygon}` (Graham scan)                                                                                                                                             | `convex_hull_test.mbt`, `property_test.mbt`      | "convex_hull n=50"                          | 🟡 (qhull not ported)                                            |
| `coordinate_position::CoordinatePosition` + `CoordPos`                                                                                                                                                                                                                                                                                                                              | `coord_position_for_{geometry, line, line_string, polygon, multi_polygon, rect, triangle}` + `CoordPos` enum (`OnBoundary`, `Inside`, `Outside`)                                                                         | `topology_test.mbt`                              |                                             | ✅                                                               |
| `coordinate_position::coord_pos_relative_to_ring`                                                                                                                                                                                                                                                                                                                                   | (used internally; not re-exported)                                                                                                                                                                                       | —                                                |                                             | 🟡                                                               |
| `coords_iter::CoordsIter`                                                                                                                                                                                                                                                                                                                                                           | `coords_of_{geometry, geometry_collection, point, line, line_string, multi_point, multi_line_string, polygon, multi_polygon, rect, triangle}` + `coords_count` + `exterior_coords_of_{geometry, polygon, multi_polygon}` | `iteration_test.mbt`                             | "coords_of_polygon n=100"                   | ✅                                                               |
| `covers::Covers`                                                                                                                                                                                                                                                                                                                                                                    | `covers_{polygon_point, polygon_coord, polygon_line_string, polygon_polygon, rect_coord, geometry}`                                                                                                                      | `containment_test.mbt`                           |                                             | ✅                                                               |
| `dimensions::HasDimensions::dimensions/is_empty` + `Dimensions` enum                                                                                                                                                                                                                                                                                                                | `dimensions_of_{geometry, line_string, rect}` + `is_empty_of_geometry` + `Dimensions` enum (`Empty`, `ZeroDimensional`, `OneDimensional`, `TwoDimensional`) + `Dimensions::rank` + `dimensions_less`                     | `measure_test.mbt`                               |                                             | ✅                                                               |
| `extremes::Extremes::extremes` + `Outcome`                                                                                                                                                                                                                                                                                                                                          | `extremes_of_{coords, geometry}` + `Outcome` (4 fields: `x_min`, `x_max`, `y_min`, `y_max`)                                                                                                                              | `shape_test.mbt`                                 |                                             | ✅                                                               |
| `extremes::Extreme<T>` (index + coord)                                                                                                                                                                                                                                                                                                                                              | —                                                                                                                                                                                                                        | —                                                |                                             | 🟡 (only the four extremes, no indices)                          |
| `frechet_distance::FrechetDistance`                                                                                                                                                                                                                                                                                                                                                 | `frechet_distance(LineString, LineString)`                                                                                                                                                                               | `distance_metrics_test.mbt`, `property_test.mbt` | "frechet_distance n=20 vs n=20"             | ✅                                                               |
| `hausdorff_distance::HausdorffDistance`                                                                                                                                                                                                                                                                                                                                             | `hausdorff_distance_{coords, geometry}`                                                                                                                                                                                  | `distance_metrics_test.mbt`, `property_test.mbt` | "hausdorff_distance n=50 vs n=50"           | ✅                                                               |
| `intersects::Intersects` (collections + atoms)                                                                                                                                                                                                                                                                                                                                      | `intersects_{coord_coord, coord_line, coord_line_string, coord_polygon, line_line, line_line_string, line_polygon, line_string_line_string, polygon_polygon, rect_coord, geometry}`                                      | `topology_test.mbt`                              | "line_intersection crossing"                | ✅                                                               |
| `is_convex::IsConvex::is_convex/is_strictly_convex`                                                                                                                                                                                                                                                                                                                                 | `is_convex(LineString)`, `is_strictly_convex(LineString)`                                                                                                                                                                | `shape_test.mbt`                                 |                                             | ✅                                                               |
| `kernels::Kernel::orient2d` + `Orientation`                                                                                                                                                                                                                                                                                                                                         | `orient(Coord, Coord, Coord) -> Orientation` + enum                                                                                                                                                                      | `kernel_test.mbt`                                | "orient2d (robust)"                         | ✅                                                               |
| `kernels::RobustKernel`, `SimpleKernel`                                                                                                                                                                                                                                                                                                                                             | (single robust impl via `robust::orient2d` + Vitalik fallback)                                                                                                                                                           | (same)                                           |                                             | 🟡                                                               |
| `line_intersection::line_intersection` + `LineIntersection`                                                                                                                                                                                                                                                                                                                         | `line_intersection(Line, Line) -> LineIntersection?` + enum (`SinglePoint(Coord, Bool)`, `Collinear(Line)`)                                                                                                              | `closest_test.mbt`                               |                                             | ✅                                                               |
| `line_interpolate_point::LineInterpolatePoint`                                                                                                                                                                                                                                                                                                                                      | `line_interpolate_point(Line, Double)`, `line_string_interpolate_point(LineString, Double)`                                                                                                                              | `closest_test.mbt`, `property_test.mbt`          |                                             | ✅                                                               |
| `line_locate_point::LineLocatePoint`                                                                                                                                                                                                                                                                                                                                                | `line_locate_point(Line, Coord)`, `line_string_locate_point(LineString, Coord)`                                                                                                                                          | `closest_test.mbt`, `property_test.mbt`          |                                             | ✅                                                               |
| `line_measures::Bearing` for `Euclidean`                                                                                                                                                                                                                                                                                                                                            | `euclidean_bearing(Coord, Coord)`                                                                                                                                                                                        | `vector_distance_test.mbt`                       |                                             | ✅                                                               |
| `line_measures::Destination` for `Euclidean`                                                                                                                                                                                                                                                                                                                                        | `euclidean_destination(Coord, distance, bearing)`                                                                                                                                                                        | `vector_distance_test.mbt`                       |                                             | ✅                                                               |
| `line_measures::Distance` for `Euclidean`                                                                                                                                                                                                                                                                                                                                           | `euclidean_distance_{coords, points, coord_to_line, point_to_line, coord_to_line_string}` + `euclidean_distance_squared_coords`                                                                                          | `vector_distance_test.mbt`                       |                                             | ✅                                                               |
| `line_measures::Length` for `Euclidean`                                                                                                                                                                                                                                                                                                                                             | `euclidean_length_{line, line_string, multi_line_string}`                                                                                                                                                                | `vector_distance_test.mbt`                       | "euclidean_length_line_string n=100"        | ✅                                                               |
| `line_measures::Densify`                                                                                                                                                                                                                                                                                                                                                            | `densify_line_string(LineString, max_segment_len)`, `densify_polygon(Polygon, …)`                                                                                                                                        | `distance_metrics_test.mbt`                      |                                             | ✅                                                               |
| `line_measures::InterpolatePoint/InterpolateLine/InterpolatableLine`                                                                                                                                                                                                                                                                                                                | (collapsed into per-shape free functions above)                                                                                                                                                                          | (same)                                           |                                             | 🟡                                                               |
| `line_measures::FrechetDistance`                                                                                                                                                                                                                                                                                                                                                    | (already counted under `frechet_distance::FrechetDistance` row)                                                                                                                                                          | —                                                |                                             | ✅                                                               |
| `line_measures::metric_spaces::{Euclidean, …}`                                                                                                                                                                                                                                                                                                                                      | (only `Euclidean` is materialised; geodesic-family marker types omitted)                                                                                                                                                 | —                                                |                                             | 🟡                                                               |
| `lines_iter::LinesIter`                                                                                                                                                                                                                                                                                                                                                             | `lines_of_{geometry, geometry_collection, line, line_string, multi_line_string, multi_polygon, polygon, rect, triangle}`                                                                                                 | `iteration_test.mbt`                             |                                             | ✅                                                               |
| `map_coords::MapCoords` / `MapCoordsInPlace`                                                                                                                                                                                                                                                                                                                                        | `map_coords_in_{point, line, line_string, multi_point, multi_line_string, polygon, multi_polygon, rect, triangle, geometry, geometry_collection}`                                                                        | `iteration_test.mbt`                             |                                             | ✅                                                               |
| `orient::Orient::orient` + `Direction`                                                                                                                                                                                                                                                                                                                                              | `orient_{polygon, multi_polygon}(_, OrientDirection)` + `OrientDirection { Default, Reversed }`                                                                                                                          | `shape_test.mbt`, `property_test.mbt`            |                                             | ✅                                                               |
| `remove_repeated_points::RemoveRepeatedPoints`                                                                                                                                                                                                                                                                                                                                      | `remove_repeated_points_{line_string, polygon}`                                                                                                                                                                          | `simplify_test.mbt`                              |                                             | ✅                                                               |
| `rotate::Rotate::{rotate_around_point, rotate_around_centroid}`                                                                                                                                                                                                                                                                                                                     | `rotate_geometry_around(Geometry, angle, pivot)`, `rotate_geometry_around_centroid(Geometry, angle)`                                                                                                                     | `affine_test.mbt`                                |                                             | ✅                                                               |
| `scale::Scale`                                                                                                                                                                                                                                                                                                                                                                      | `scale_geometry(Geometry, factor)`, `scale_geometry_around(Geometry, sx, sy, origin)`                                                                                                                                    | `affine_test.mbt`, `property_test.mbt`           |                                             | ✅                                                               |
| `simplify::Simplify` (Ramer-Douglas-Peucker)                                                                                                                                                                                                                                                                                                                                        | `simplify_line_string(LineString, eps)`, `simplify_polygon(Polygon, eps)`                                                                                                                                                | `simplify_test.mbt`, `property_test.mbt`         | "simplify_line_string RDP eps=0.5"          | ✅                                                               |
| `simplify::SimplifyIdx`                                                                                                                                                                                                                                                                                                                                                             | `simplify_line_string_indices(LineString, eps)`                                                                                                                                                                          | `simplify_test.mbt`                              |                                             | ✅                                                               |
| `simplify_vw::SimplifyVw` (Visvalingam-Whyatt)                                                                                                                                                                                                                                                                                                                                      | `simplify_vw_line_string(LineString, eps)`                                                                                                                                                                               | `simplify_test.mbt`                              |                                             | ✅                                                               |
| `simplify_vw::SimplifyVwIdx` / `SimplifyVwPreserve`                                                                                                                                                                                                                                                                                                                                 | —                                                                                                                                                                                                                        | —                                                |                                             | ⏳                                                               |
| `skew::Skew`                                                                                                                                                                                                                                                                                                                                                                        | `skew_geometry(Geometry, xs, ys)`, `skew_geometry_around(Geometry, xs, ys, origin)`                                                                                                                                      | `affine_test.mbt`                                |                                             | ✅                                                               |
| `translate::Translate`                                                                                                                                                                                                                                                                                                                                                              | `translate_{point, polygon, geometry}(_, dx, dy)`                                                                                                                                                                        | `affine_test.mbt`, `property_test.mbt`           |                                             | ✅                                                               |
| `validation::Validation` + `RingRole`/`InvalidPolygon`/`InvalidLineString`/`InvalidCoord`                                                                                                                                                                                                                                                                                           | `is_valid(Geometry) -> Bool`, `validation_problems(Geometry) -> Array[ValidationProblem]` + `ValidationProblem { TooFewPoints, RingNotClosed, RingTooFewPoints, SelfIntersection, NonFiniteCoord }`                      | `validation_test.mbt`                            |                                             | 🟡 (errors flattened into one enum without `RingRole` / indices) |
| `vector_ops::Vector2DOps`                                                                                                                                                                                                                                                                                                                                                           | `dot_product`, `wedge_product`, `magnitude`, `magnitude_squared`, `try_normalize`, `is_finite`, `left`, `right`                                                                                                          | `vector_distance_test.mbt`                       |                                             | ✅                                                               |
| `winding_order::Winding` + `WindingOrder` enum                                                                                                                                                                                                                                                                                                                                      | `winding_order(LineString) -> WindingOrder?`, `reverse_line_string(LineString) -> LineString` + `WindingOrder { Clockwise, CounterClockwise }`                                                                           | `shape_test.mbt`                                 |                                             | ✅                                                               |
| `within::Within`                                                                                                                                                                                                                                                                                                                                                                    | `within_geometry(Geometry, Geometry) -> Bool`                                                                                                                                                                            | `containment_test.mbt`                           |                                             | ✅                                                               |
| `bool_ops::BooleanOps` (full DCEL via i_overlay)                                                                                                                                                                                                                                                                                                                                    | `intersection_polygon_rect(Polygon, Rect)`, `intersection_sutherland_hodgman(Polygon, Polygon)`                                                                                                                          | `bool_ops_test.mbt`                              |                                             | 🟡 (Sutherland-Hodgman only — convex clip; no union/diff/xor)    |
| `bool_ops::OpType`, `unary_union`                                                                                                                                                                                                                                                                                                                                                   | —                                                                                                                                                                                                                        | —                                                |                                             | ⛔ (i_overlay not ported)                                        |
| `relate::Relate` (DE-9IM)                                                                                                                                                                                                                                                                                                                                                           | —                                                                                                                                                                                                                        | —                                                |                                             | ⛔                                                               |
| `sweep` (Bentley-Ottmann), `monotone`, `monotone_chain`, `old_sweep`, `stitch`, `repair_polygon`                                                                                                                                                                                                                                                                                    | —                                                                                                                                                                                                                        | —                                                |                                             | ⛔                                                               |
| `triangulate_earcut`, `triangulate_delaunay`, `triangulate_spade`                                                                                                                                                                                                                                                                                                                   | —                                                                                                                                                                                                                        | —                                                |                                             | ⛔                                                               |
| `voronoi`, `dbscan`, `kmeans`, `outlier_detection`, `concave_hull`, `k_nearest_concave_hull`, `interior_point`, `minimum_rotated_rect`, `linestring_segment`, `ball_tree`, `convert`, `convert_angle_unit`, `chamberlain_duquette_area`, `cross_track_distance`, `proj`, `transform`, `buffer`, `indexed`, `densify_haversine`, `geodesic_*`, `haversine_*`, `vincenty_*`, `rhumb*` | —                                                                                                                                                                                                                        | —                                                |                                             | ⛔ (out of port scope)                                           |

### 2.3 Property tests (no direct upstream counterpart)

`property_test.mbt` — 11 invariant-style cases. They exercise composed
behaviour (e.g. _signed_area flips sign on reversal_, _bounding rect
contains every coord_, _translate is invertible_, _simplify preserves
endpoints_, _line_locate ∘ line_interpolate ≈ id_, _orient_polygon is
idempotent_, _hausdorff_distance is symmetric_, _scale preserves shape_).

### 2.4 Benchmarks

All benches live in `geo/2d/bench_test.mbt` (14 cases) and use
`@bench.T` from MoonBit's standard benchmark harness. There is **no
direct counterpart** in `geo-benches/` — upstream uses Criterion across
many crates. Coverage:

| Bench                                       | Targets                                                   |
| ------------------------------------------- | --------------------------------------------------------- |
| `bounding_rect_of_line_string n=100`        | `bounding_rect`                                           |
| `signed_area_of_polygon n=100`              | `area`                                                    |
| `centroid_polygon n=100`                    | `centroid`                                                |
| `euclidean_length_line_string n=100`        | `line_measures::Length / Euclidean`                       |
| `contains_polygon_coord n=100`              | `contains`                                                |
| `convex_hull n=50`                          | `convex_hull` (Graham)                                    |
| `simplify_line_string RDP eps=0.5`          | `simplify`                                                |
| `line_intersection crossing`                | `line_intersection`                                       |
| `orient2d (robust)`                         | `kernels::RobustKernel` + `robust::orient2d`              |
| `frechet_distance n=20 vs n=20`             | `frechet_distance`                                        |
| `hausdorff_distance n=50 vs n=50`           | `hausdorff_distance`                                      |
| `coords_of_polygon n=100`                   | `coords_iter`                                             |
| `affine transform translate+rotate compose` | `affine_ops::AffineTransform::{translate,rotate,compose}` |
| `chaikin_smoothing 3 iterations`            | `chaikin_smoothing`                                       |

---

## 3. `robust` ↔ `src/robust/`

Port package: `totto2727/geo-mbt/robust` (`src/robust/pkg.generated.mbti`).
The port preserves Shewchuk's helper hierarchy verbatim; it tracks the
upstream Rust `robust` crate (georust) which itself transliterates
Shewchuk's reference implementation.

### 3.1 Public predicates

| Rust upstream item                          | MoonBit port                                     | Status | Notes                    |
| ------------------------------------------- | ------------------------------------------------ | ------ | ------------------------ |
| `pub fn orient2d<T>(pa, pb, pc) -> f64`     | `orient2d(Coord, Coord, Coord) -> Double`        | ✅     | Same return contract     |
| `pub fn incircle<T>(pa, pb, pc, pd) -> f64` | `incircle(Coord, Coord, Coord, Coord) -> Double` | ✅     |                          |
| `pub fn orient3d<T>(pa, pb, pc, pd) -> f64` | —                                                | ⛔     | 3D out of scope          |
| `pub fn insphere<T>(...) -> f64`            | —                                                | ⛔     | 3D out of scope          |
| `pub struct Coord<T>`                       | (uses `@type.Coord`)                             | ✅     | Port reuses geo-2d coord |
| `pub struct Coord3D<T>`                     | —                                                | ⛔     |                          |

### 3.2 Internal helpers (Shewchuk primitives) — `expansion.mbt`

Upstream marks these `fn` (private to the crate); the port re-exports
them as `pub` so that downstream MoonBit code can build other
expansion-based predicates without forking the file.

| Rust private fn                       | MoonBit port                                                                    | Status |
| ------------------------------------- | ------------------------------------------------------------------------------- | ------ | -------------------------------------------- |
| `two_sum`                             | `two_sum(Double, Double) -> (Double, Double)`                                   | ✅     |
| `two_sum_tail`                        | `two_sum_tail(Double, Double, Double) -> Double`                                | ✅     |
| `fast_two_sum`                        | `fast_two_sum(Double, Double) -> (Double, Double)`                              | ✅     |
| `fast_two_sum_tail`                   | `fast_two_sum_tail(Double, Double, Double) -> Double`                           | ✅     |
| `two_diff`                            | `two_diff(Double, Double) -> (Double, Double)`                                  | ✅     |
| `two_diff_tail`                       | `two_diff_tail(Double, Double, Double) -> Double`                               | ✅     |
| `split`                               | `split(Double) -> (Double, Double)`                                             | ✅     |
| `two_product`                         | `two_product(Double, Double) -> (Double, Double)`                               | ✅     |
| `two_product_tail` (private)          | (folded into `two_product`)                                                     | 🟡     |
| `two_product_presplit`                | `two_product_presplit(Double, Double, Double, Double) -> (Double, Double)`      | ✅     |
| `square`                              | `square(Double) -> (Double, Double)`                                            | ✅     |
| `square_tail`                         | `square_tail(Double, Double) -> Double`                                         | ✅     |
| (combinator helpers, unnamed in Rust) | `two_one_sum`, `two_one_diff`, `two_two_sum`, `two_two_diff`, `two_one_product` | ✅     |
| `estimate`                            | `estimate(Array[Double], Int) -> Double`                                        | ✅     | Port adds explicit `len` arg (no Rust slice) |
| `fast_expansion_sum_zeroelim`         | `fast_expansion_sum_zeroelim(e, ne, f, nf, h) -> Int`                           | ✅     | Same — explicit lengths                      |
| `scale_expansion_zeroelim`            | `scale_expansion_zeroelim(e, ne, b, h) -> Int`                                  | ✅     |                                              |

### 3.3 Numeric constants

| Rust upstream constant    | MoonBit port     | Value (port)                                   |
| ------------------------- | ---------------- | ---------------------------------------------- |
| `EPSILON`                 | `EPSILON`        | `0.000_000_000_000_000_111_022_302_462_515_65` |
| `SPLITTER`                | `SPLITTER`       | `134_217_729.0`                                |
| `RESULTERRBOUND`          | `RESULTERRBOUND` | `3.33066907388e-16`                            |
| `CCWERRBOUND_A` (private) | (inlined)        | —                                              |
| `CCWERRBOUND_B`           | `CCWERRBOUND_B`  | `2.22044604925e-16`                            |
| `CCWERRBOUND_C`           | `CCWERRBOUND_C`  | `1.10933564797e-31`                            |
| `ICCERRBOUND_A`           | `ICCERRBOUND_A`  | `1.11022302463e-15`                            |
| `ICCERRBOUND_B`           | `ICCERRBOUND_B`  | `4.4408920985e-16`                             |
| `ICCERRBOUND_C`           | `ICCERRBOUND_C`  | `5.42341872339e-31`                            |

### 3.4 Tests / benches

`robust/robust_test.mbt` — 6 cases:

- `orient2d collinear`, `orient2d counter-clockwise`, `orient2d clockwise`
- `orient2d high-precision tiny inputs`
- `incircle basic — point inside`, `incircle basic — point outside`

Upstream has a `tests.rs` (~30 unit tests) plus `fuzz/` targets.
Port has no fuzzing harness yet (deferred per roadmap post-scope #4).
Robust predicates are also exercised through the `geo/2d` bench
`orient2d (robust)`.

---

## 4. `rstar` ↔ `src/rtree/`

Port package: `totto2727/geo-mbt/rtree` (`src/rtree/pkg.generated.mbti`).
This was added **after** the documented scope (`CLAUDE.md` lists R-tree
as deferred) as a minimal bulk-loaded R-tree usable in 2D. It ports
only a small subset of `rstar`.

### 4.1 Types

| Rust upstream item                                                                      | MoonBit port                                                       | Status | Notes                                         |
| --------------------------------------------------------------------------------------- | ------------------------------------------------------------------ | ------ | --------------------------------------------- |
| `pub struct RTree<T, Params = DefaultParams>`                                           | `pub struct RTree[T] { root: Node[T]?, size: Int }`                | 🟡     | No tunable params; default fanout fixed       |
| `pub trait RTreeObject` + `Envelope` assoc type                                         | `pub struct Entry[T] { bbox: Rect, value: T }` (explicit envelope) | 🟡     | Port carries the envelope alongside the value |
| `pub struct AABB<P>`                                                                    | (uses `@type.Rect`)                                                | ✅     | Reuses 2D rect                                |
| `pub trait Point`, `RTreeNum`, `PointExt`                                               | —                                                                  | ⛔     | Generic point machinery not needed            |
| `pub trait Envelope`                                                                    | —                                                                  | ⛔     | Single concrete envelope                      |
| `pub trait PointDistance`                                                               | —                                                                  | ⛔     | Hard-coded squared-distance to bbox           |
| `pub trait RTreeParams`, `DefaultParams`, `InsertionStrategy`, `RStarInsertionStrategy` | — (uses STR-style bulk load only)                                  | ⛔     |                                               |
| `pub trait SelectionFunction`                                                           | —                                                                  | ⛔     |                                               |
| `pub struct ParentNode`, `pub enum RTreeNode`                                           | `type Node[T]` (opaque)                                            | 🟡     | Internal-only — not exposed                   |
| `iterators` module (`RTreeIterator`, `LocateIn*`, `DrainIterator`, …)                   | —                                                                  | ⛔     |                                               |
| `mint` integration                                                                      | —                                                                  | ⛔     |                                               |
| `primitives::{GeomWithData, ObjectRef, Rectangle, Line, PointWithData, CachedEnvelope}` | `Entry[T]` only                                                    | 🟡     |                                               |

### 4.2 `RTree` methods

Upstream `RTree<T, P>` exposes ~46 public methods. The port surfaces the
five most useful for static spatial indexing:

| Rust method                                                                                                                                                                                                                                                                                                                         | MoonBit port                                                | Status                             |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------- | ---------------------------------- | --------------------------- |
| `RTree::bulk_load(elements: Vec<T>) -> Self`                                                                                                                                                                                                                                                                                        | `RTree::bulk_load(Array[Entry[T]]) -> Self[T]`              | ✅                                 |
| `RTree::size(&self) -> usize`                                                                                                                                                                                                                                                                                                       | `RTree::size(Self[T]) -> Int`                               | ✅                                 |
| (no direct rstar equiv — derived from `size == 0`)                                                                                                                                                                                                                                                                                  | `RTree::is_empty(Self[T]) -> Bool`                          | ✅                                 |
| `RTree::locate_in_envelope_intersecting(&self, env)` (returns iterator)                                                                                                                                                                                                                                                             | `RTree::query_rect_intersection(Self[T], Rect) -> Array[T]` | 🟡 (returns `Array`, not iterator) |
| `RTree::nearest_neighbor(&self, p) -> Option<&T>`                                                                                                                                                                                                                                                                                   | `RTree::query_nearest(Self[T], Coord) -> T?`                | ✅                                 |
| `new`, `bulk_load_with_params`, `iter`, `iter_mut`, `locate_at_point*`, `locate_all_at_point*`, `locate_within_distance`, `nearest_neighbors*`, `nearest_neighbor_with_distance_2`, `nearest_neighbor_iter*`, `intersection_candidates_with_other_tree`, `locate_with_selection_function*`, `drain*`, `remove*`, `contains`, `root` | —                                                           | ⏳ / ⛔ (post-scope)               |
| `Entry::new(Rect, T)` (port-only convenience)                                                                                                                                                                                                                                                                                       | `Entry::new(Rect, T) -> Entry[T]`                           | ✅                                 | No direct rstar counterpart |

### 4.3 Tests / benches

`rtree/rtree_test.mbt` — 6 cases:

- `empty RTree`, `single entry intersection`, `many entries: rectangular query`
- `query_nearest: empty returns None`, `query_nearest: returns the nearest entry`
- `exhaustive verification: query against all entries`

`rtree/bench_test.mbt` — 4 cases:

- `bench: RTree::bulk_load n=1000`
- `bench: RTree::query_rect_intersection n=1000 small query`
- `bench: RTree::query_rect_intersection n=1000 large query`
- `bench: RTree::query_nearest n=1000`

Compare to `rstar-benches/benches/benchmarks.rs`:
`bulk load baseline`, `insert sequential`, `Bulk load complex geo-types
geom`, `bulk load quality`, `locate_at_point (successful/unsuccessful)`,
`locate_at_point_int (successful/unsuccessful)`. The port covers the
bulk-load + query subset only.

---

## 5. Aggregate test / bench counts

Counted across the port (`grep -rE '^(test|bench) "' src/`):

| Package       | Test files                                                                                                                                                                                                                                                                                                                                                                    | Tests   | Benches |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- | ------- |
| `geo/2d/type` | `coord_test.mbt`, `point_test.mbt`, `line_test.mbt`, `line_string_test.mbt`, `polygon_test.mbt`, `rect_test.mbt`, `triangle_test.mbt`, `multi_point_test.mbt`, `multi_line_string_test.mbt`, `multi_polygon_test.mbt`, `geometry_collection_test.mbt`                                                                                                                         | 53      | 0       |
| `geo/2d`      | `affine_test.mbt`, `bool_ops_test.mbt`, `closest_test.mbt`, `containment_test.mbt`, `convex_hull_test.mbt`, `distance_metrics_test.mbt`, `iteration_test.mbt`, `kernel_test.mbt`, `measure_test.mbt`, `property_test.mbt`, `shape_test.mbt`, `simplify_test.mbt`, `topology_test.mbt`, `traits_test.mbt`, `validation_test.mbt`, `vector_distance_test.mbt`, `bench_test.mbt` | 137     | 14      |
| `robust`      | `robust_test.mbt`                                                                                                                                                                                                                                                                                                                                                             | 6       | 0       |
| `rtree`       | `rtree_test.mbt`, `bench_test.mbt`                                                                                                                                                                                                                                                                                                                                            | 6       | 4       |
| **Total**     |                                                                                                                                                                                                                                                                                                                                                                               | **202** | **18**  |

Reconciliation: `grep -rE '^test "' --include='*.mbt'` reports `220`,
because MoonBit's bench blocks share the `test "..." { ... }` syntax.
Splitting on the handler signature (`(b : @bench.T)` → bench, otherwise
→ unit test) gives `202 + 18 = 220`.

---

## 6. Update procedure

When upstream snapshots are refreshed:

1. `git -C ~/proj/geo/<lib> log -1 --format='%H %ai %s'` to capture the
   new commit + date.
2. `grep -E '^(name|version|edition)' ~/proj/geo/<lib>/Cargo.toml` for
   the crate version.
3. Update the table at the top of this file.
4. Re-diff the relevant module(s) under `~/proj/geo/<lib>/src/` against
   the port's `pkg.generated.mbti` (run `moon info` first if `.mbti` is
   stale) and refresh the Status column for any items whose upstream
   signature changed.
