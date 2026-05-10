# ms-16 — Current state of `mbt/package/geo-mbt/`

Investigation snapshot for ms-16 ("Trait Surface Expansion + Small ⏳ Items").

Roadmap scope (`docs/roadmap/geo-mbt/roadmap-progress.yaml:152-162`):

> Unify pairwise predicates (Contains/Covers/Intersects/Within) into traits;
> absorb the long tail of ⏳ items (Polygon::empty, Triangle CCW ctor,
> AffineTransform inverse/scaled/compose_many/is_identity, MultiPoint From\*,
> etc.).

---

## 1. Current trait surface in `type/traits.mbt`

File: `mbt/package/geo-mbt/src/geo/2d/type/traits.mbt` (36 lines).
Three traits, all `pub(open)`, all constraint-only (zero default methods).

```mbt
// type/traits.mbt:20-22
pub(open) trait IsEmpty {
  is_empty(Self) -> Bool
}

// type/traits.mbt:26-28
pub(open) trait IsClosed {
  is_closed(Self) -> Bool
}

// type/traits.mbt:34-36
pub(open) trait HasLength {
  length(Self) -> Int
}
```

Doc-block (lines 8-15) explicitly notes that the algorithm-layer traits
(`CoordsCarrier`, `Bounded`, `HasArea`, `HasCentroid`, `HasEuclideanLength`,
`LinesCarrier`, `HasDimensions`, `HasConvexHull`, `HasExtremes`,
`ExteriorCoordsCarrier`, `ClosestPoint`, `CoordPositionFor`, `Simplify`,
`Densify`, `MapCoords`) live colocated with their impls in each
algorithm-layer source file under `geo/2d/`, and that the previously
monolithic `geo/2d/traits.mbt` was dismantled in commit `c8b61f2`.

**Implication for ms-16**: there is currently _no_ trait covering pairwise
predicates (Contains / Covers / Intersects / Within). The three existing
traits in this file all have `Self`-only signatures.

---

## 2. Pairwise predicates current state

All three predicate files use the **`<op>_<a>_<b>(a, b)` free-function
dispatch** style, with a single `<op>_geometry(Geometry, Geometry)` enum-
dispatcher at the bottom. None of them have a trait. There are no
inherent methods on `Polygon`/`Rect`/etc. for these predicates either
(grep confirmed).

### 2.1 `geo/2d/contains.mbt` (149 lines)

```text
contains.mbt:7    pub fn contains_polygon_coord(polygon: Polygon, coord: Coord) -> Bool
contains.mbt:19   pub fn contains_polygon_point(polygon: Polygon, point: Point) -> Bool
contains.mbt:29   pub fn contains_polygon_line(polygon: Polygon, line: Line) -> Bool
contains.mbt:61   pub fn contains_polygon_line_string(polygon: Polygon, ls: LineString) -> Bool
contains.mbt:72   pub fn contains_polygon_polygon(outer: Polygon, inner: Polygon) -> Bool
contains.mbt:94   pub fn contains_multi_polygon_coord(mp: MultiPolygon, coord: Coord) -> Bool
contains.mbt:103  pub fn contains_rect_coord(rect: Rect, coord: Coord) -> Bool
contains.mbt:112  pub fn contains_rect_rect(outer: Rect, inner: Rect) -> Bool
contains.mbt:121  pub fn contains_geometry(outer: Geometry, inner: Geometry) -> Bool
contains.mbt:147  pub fn within_geometry(inner: Geometry, outer: Geometry) -> Bool
```

`within_geometry` is the only `within` implementation in the package
(grep `within|Within` over `src/**/*.mbt` excluding tests turned up only
docstring uses + this single function). It is a one-liner inverse of
`contains_geometry`:

```mbt
// contains.mbt:147-149
pub fn within_geometry(inner : @type.Geometry, outer : @type.Geometry) -> Bool {
  contains_geometry(outer, inner)
}
```

`contains_geometry` (lines 121-143) explicitly enumerates 8 ordered pairs
(Polygon×{Point, Line, LineString, Polygon}, Rect×{Point, Rect},
MultiPolygon×Point, Point×Point) plus a `_ => false` fallback. **Pairs
not covered by a dedicated `contains_*_*` helper are silently `false`.**

### 2.2 `geo/2d/covers.mbt` (67 lines)

```text
covers.mbt:9    pub fn covers_polygon_coord(polygon: Polygon, coord: Coord) -> Bool
covers.mbt:20   pub fn covers_polygon_point(polygon: Polygon, point: Point) -> Bool
covers.mbt:28   pub fn covers_polygon_line_string(polygon: Polygon, ls: LineString) -> Bool
covers.mbt:36   pub fn covers_polygon_polygon(outer: Polygon, inner: Polygon) -> Bool
covers.mbt:44   pub fn covers_rect_coord(rect: Rect, coord: Coord) -> Bool
covers.mbt:53   pub fn covers_geometry(a: Geometry, b: Geometry) -> Bool
```

`covers_geometry` (lines 53-67) handles 5 pairs explicitly, then falls
through to `contains_geometry(a, b)` (line 65) for everything else —
i.e. covers reuses contains' enum dispatch for the long tail.

### 2.3 `geo/2d/intersects.mbt` (181 lines)

The widest predicate surface — 11 pair helpers + the enum dispatcher:

```text
intersects.mbt:6    intersects_coord_coord(Coord, Coord)
intersects.mbt:12   intersects_coord_line(Coord, Line)
intersects.mbt:19   intersects_line_line(Line, Line)             // robust, with collinear cases
intersects.mbt:53   intersects_coord_line_string(Coord, LineString)
intersects.mbt:61   intersects_line_line_string(Line, LineString)
intersects.mbt:69   intersects_line_string_line_string(LineString, LineString)
intersects.mbt:79   intersects_coord_polygon(Coord, Polygon)
intersects.mbt:87   intersects_line_polygon(Line, Polygon)
intersects.mbt:107  intersects_polygon_polygon(Polygon, Polygon)
intersects.mbt:125  intersects_rect_coord(Rect, Coord)
intersects.mbt:136  intersects_geometry(Geometry, Geometry)
```

`intersects_geometry` (lines 136-180) enumerates 14 ordered pairs
including symmetric reversals (Point×Line and Line×Point both),
recurses into `GeometryCollection`, and **falls back to a bounding-rect
overlap test for every uncovered pair** (lines 170-179). This is the
only predicate dispatcher with a non-`false` fallback.

### 2.4 Cross-cutting observation

- All three operate on **free functions named after both operand types**
  (`<op>_<a>_<b>`). Dispatch is purely by the function name — no
  ad-hoc polymorphism.
- The `Geometry` enum dispatcher is the only generic entry point.
- There is **no `Within` trait** and no per-type `within` helpers — only
  the one-liner `within_geometry`.
- Coverage matrix is uneven: `Contains` covers 8 pairs, `Covers` 5,
  `Intersects` 14. ms-16's "unify into traits" goal will need to decide
  whether the trait surface mirrors the **union** of pairs (covering all
  of intersects' coverage even where contains is silent) or just locks
  in today's gaps as the contract.

---

## 3. ⏳ / deferred / TODO items in `*.mbt` source files

Search command:
`grep -rn -E '(TODO|FIXME|deferred|⏳|not yet|not implemented)' src/ --include='*.mbt' | grep -v '_test.mbt' | grep -v '_wbtest.mbt'`

**Result: 0 hits.** No `TODO`, `FIXME`, `deferred`, `⏳`, "not yet" or
"not implemented" markers appear in any `.mbt` source file under
`src/`. All deferred work is tracked in `api-correspondence.md` (item 8
below) and `docs/roadmap/geo-mbt/`, **not** inline in the code.

---

## 4. `Polygon::empty` / `is_empty` state across collection types

`type/polygon.mbt` (95 lines):

```text
polygon.mbt:35-42  pub fn Polygon::Polygon(exterior, interiors) -> Polygon  // canonical, auto-closes rings
polygon.mbt:73-75  pub impl IsEmpty for Polygon with is_empty(self) {
                     self.exterior.is_empty()
                   }
polygon.mbt:90-94  pub fn Polygon::pushed_interior(...) -> Polygon
```

**No `Polygon::empty()` factory exists** — confirmed by `api-correspondence.md:171`
which marks it ⏳. The only constructor is the canonical
`Polygon::Polygon(LineString, Array[LineString])`. There is, however,
an `IsEmpty` trait impl (lines 73-75) that returns `self.exterior.is_empty()`.

For comparison, the four other collection types **already** have
`empty()` factories:

```text
multi_polygon.mbt:18-20      MultiPolygon::empty() -> MultiPolygon
multi_polygon.mbt:33-34      impl IsEmpty for MultiPolygon
line_string.mbt:32-34        LineString::empty() -> LineString
line_string.mbt:69-71        impl IsEmpty for LineString
multi_line_string.mbt:20-22  MultiLineString::empty() -> MultiLineString
multi_line_string.mbt:37-39  impl IsEmpty for MultiLineString
multi_point.mbt:23-25        MultiPoint::empty() -> MultiPoint
multi_point.mbt:38-40        impl IsEmpty for MultiPoint
```

**Polygon is the lone outlier**: it lacks the `empty()` factory but
already has the `IsEmpty` impl — so ms-16 only needs to add the
factory. The natural shape, given the immutable-port idiom and
mirroring `MultiPolygon::empty`, would be:

```mbt
pub fn Polygon::empty() -> Polygon {
  Polygon::Polygon(LineString::empty(), [])
}
```

---

## 5. Triangle constructors — port vs upstream

### Port: `type/triangle.mbt` (48 lines)

Single canonical constructor + 3 accessors + 2 conversions:

```text
triangle.mbt:13-15  pub fn Triangle::Triangle(v0, v1, v2) -> Triangle   // canonical
triangle.mbt:18-20  pub fn Triangle::v0(self) -> Coord
triangle.mbt:23-25  pub fn Triangle::v1(self) -> Coord
triangle.mbt:28-30  pub fn Triangle::v2(self) -> Coord
triangle.mbt:35-41  pub fn Triangle::to_lines(self) -> Array[Line]
triangle.mbt:45-48  pub fn Triangle::to_polygon(self) -> Polygon
```

The canonical constructor stores vertices **as given** with no winding
check — semantically equivalent to upstream's `unchecked_winding`, not
upstream's `new`. (Confirmed by `api-correspondence.md:208-211`:
"Winding-order normalisation is NOT implemented in the port. The
canonical constructor below stores vertices as-given regardless of
CW / CCW input — i.e. it is semantically `unchecked_winding`, not
upstream's CCW-enforcing `Triangle::new`.")

### Upstream: `~/proj/geo/georust-geo/geo-types/src/geometry/triangle.rs`

```text
triangle.rs:37   pub fn new(v1, v2, v3) -> Self                       // CCW-normalising
triangle.rs:55   pub fn unchecked_winding(v1, v2, v3) -> Self
triangle.rs:116  impl<IC: Into<Coord<T>> + Copy, T: CoordNum> From<[IC; 3]> for Triangle<T>
```

### Gap for ms-16

| Upstream                          | Port today                       | Gap                                                                                                                                                 |
| --------------------------------- | -------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Triangle::new` (CCW-normalising) | —                                | **Missing** — needs a CCW-flipping factory (e.g. `Triangle::ccw(v0, v1, v2)`) that uses `@robust.orient2d` to detect CW input and swap two vertices |
| `Triangle::unchecked_winding`     | `Triangle::Triangle(v0, v1, v2)` | Already covered by canonical ctor                                                                                                                   |
| `From<[IC; 3]>`                   | —                                | Could add a `Triangle::from_array(Array[Coord])` helper if desired (lower priority)                                                                 |

---

## 6. AffineTransform — port vs upstream

### Port: `geo/2d/affine_transform.mbt` (155 lines)

The port models the matrix as a **pair of `AffineRow`s** (`row_x`, `row_y`)
rather than upstream's flat `(a, b, xoff, d, e, yoff)` six-tuple.

Constructors and methods present in the port:

```text
affine_transform.mbt:26-32   AffineRow::AffineRow(scale, skew, translate)
affine_transform.mbt:44-49   AffineTransform::AffineTransform(row_x, row_y)
affine_transform.mbt:53-55   AffineTransform::identity() -> Self
affine_transform.mbt:59-64   AffineTransform::translate_xy(xoff, yoff) -> Self
affine_transform.mbt:68-73   AffineTransform::scale_xy(xfact, yfact) -> Self
affine_transform.mbt:81-86   AffineTransform::rotate_origin(degrees) -> Self
affine_transform.mbt:94-101  AffineTransform::skew_origin(xs_deg, ys_deg) -> Self
affine_transform.mbt:105-113 .apply(c: Coord) -> Coord
affine_transform.mbt:119-144 .compose(other) -> Self
affine_transform.mbt:150-154 .transform[T : MapCoords](x: T) -> T
```

### Upstream: `~/proj/geo/georust-geo/geo/src/algorithm/affine_ops.rs`

```text
affine_ops.rs:138  pub fn compose(&self, other: &Self) -> Self
affine_ops.rs:196  pub fn compose_many(&self, transforms: &[Self]) -> Self
affine_ops.rs:211  pub fn identity() -> Self
affine_ops.rs:238  pub fn is_identity(&self) -> bool
affine_ops.rs:256  pub fn scale(xfact, yfact, origin: impl Into<Coord<T>>) -> Self
affine_ops.rs:269  pub fn scaled(mut self, xfact, yfact, origin) -> Self
affine_ops.rs:282  pub fn translate(xoff, yoff) -> Self
affine_ops.rs:290  pub fn translated(mut self, xoff, yoff) -> Self
affine_ops.rs:296  pub fn apply(&self, coord) -> Coord
affine_ops.rs:311  pub fn new(a, b, xoff, d, e, yoff) -> Self
affine_ops.rs:345  pub fn inverse(&self) -> Option<Self> where T: AbsDiffEq + Float
affine_ops.rs:417  pub fn rotate(degrees, origin) -> Self
affine_ops.rs:433  pub fn rotated(mut self, angle, origin) -> Self
affine_ops.rs:454  pub fn skew(xs, ys, origin) -> Self
affine_ops.rs:480  pub fn skewed(mut self, xs, ys, origin) -> Self
```

### Gap matrix for ms-16

| Upstream                             | Port today                      | Gap / note                                                                                                     |
| ------------------------------------ | ------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `new(a, b, xoff, d, e, yoff)`        | `AffineTransform(row_x, row_y)` | Different shape — upstream's flat 6-arg ctor not provided. Optional.                                           |
| `identity()`                         | `identity()`                    | ✅                                                                                                             |
| `apply()`                            | `apply()`                       | ✅                                                                                                             |
| `compose()`                          | `compose()`                     | ✅                                                                                                             |
| `translate(xoff, yoff)`              | `translate_xy(xoff, yoff)`      | ✅ (renamed)                                                                                                   |
| `scale(xfact, yfact, origin)`        | `scale_xy(xfact, yfact)`        | 🟡 — origin-less only                                                                                          |
| `rotate(degrees, origin)`            | `rotate_origin(degrees)`        | 🟡 — origin-less only (name is misleading: "origin" here means rotates around origin, not configurable origin) |
| `skew(xs, ys, origin)`               | `skew_origin(xs, ys)`           | 🟡 — origin-less only                                                                                          |
| `translated(self, xoff, yoff)`       | —                               | **⏳** — wither                                                                                                |
| `scaled(self, xfact, yfact, origin)` | —                               | **⏳** — wither                                                                                                |
| `rotated(self, degrees, origin)`     | —                               | **⏳** — wither                                                                                                |
| `skewed(self, xs, ys, origin)`       | —                               | **⏳** — wither                                                                                                |
| `compose_many(transforms: &[Self])`  | —                               | **⏳**                                                                                                         |
| `inverse() -> Option<Self>`          | —                               | **⏳** — needs determinant + 2×2 inversion                                                                     |
| `is_identity() -> bool`              | —                               | **⏳** — exact-equality vs identity matrix                                                                     |

`api-correspondence.md:383` lists the seven missing items as ⏳:

> `AffineTransform::{scaled, translated, rotated, skewed, compose_many, inverse, is_identity}`

The four origin-aware variants (`scale` / `rotate` / `skew` with explicit
origin point) are also conceptually missing, though not enumerated as
⏳ — ms-16 may want to fold them in when adding `scaled` / `rotated` /
`skewed` since the wither + origin-aware overload are typically built
together upstream.

---

## 7. MultiPoint `From*` — port vs upstream

### Port: `type/multi_point.mbt` (40 lines)

```text
multi_point.mbt:12-14  MultiPoint::MultiPoint(points: Array[Point]) -> Self  // canonical
multi_point.mbt:17-19  MultiPoint::from_tuples(tuples: Array[(Double, Double)]) -> Self
multi_point.mbt:23-25  MultiPoint::empty() -> Self
multi_point.mbt:28-30  MultiPoint::points(self) -> Array[Point]
multi_point.mbt:33-35  impl HasLength for MultiPoint
multi_point.mbt:38-40  impl IsEmpty for MultiPoint
```

### Upstream: `~/proj/geo/georust-geo/geo-types/src/geometry/multi_point.rs`

```text
multi_point.rs:38   impl<T: CoordNum, IP: Into<Point<T>>> From<IP> for MultiPoint<T>
multi_point.rs:46   impl<T: CoordNum, IP: Into<Point<T>>> From<Vec<IP>> for MultiPoint<T>
multi_point.rs:135  pub fn new(value: Vec<Point<T>>) -> Self
multi_point.rs:140  pub fn empty() -> Self
```

The two `From<…>` impls in upstream cover:

1. `From<P>` where `P: Into<Point>` — i.e. `MultiPoint::from(point)` for
   a single point, single tuple `(f64, f64)`, single `Coord`, or
   single `[f64; 2]`.
2. `From<Vec<P>>` — i.e. `MultiPoint::from(vec_of_points_or_coords_or_tuples)`.

### Gap for ms-16

`api-correspondence.md:232` marks both as ⏳ ("Could add as ergonomic
helpers"). The MoonBit-idiomatic shape for these would be named
factories rather than trait-based `From` (the port already uses this
convention — `Coord::from_tuple`, `Coord::from_array`, etc.):

| Upstream                | Suggested port shape                                                |
| ----------------------- | ------------------------------------------------------------------- |
| `From<Point>`           | `MultiPoint::from_point(p: Point) -> Self` (length-1 multipoint)    |
| `From<Coord>`           | `MultiPoint::from_coord(c: Coord) -> Self` (length-1)               |
| `From<Vec<Point>>`      | already covered by canonical `MultiPoint::MultiPoint(Array[Point])` |
| `From<Vec<Coord>>`      | `MultiPoint::from_coords(Array[Coord]) -> Self`                     |
| `From<Vec<(f64, f64)>>` | already covered by `MultiPoint::from_tuples`                        |

---

## 8. `api-correspondence.md` — ⏳ entries

File: `mbt/package/geo-mbt/api-correspondence.md` (667 lines).

Eight `⏳` matches; line 37 is the legend definition, the remaining
seven are real deferrals:

| Line | Item                                                                                         | In ms-16 scope?                                                                                                        |
| ---- | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| 37   | Legend definition (`⏳ = Not yet ported but in scope (deferred)`)                            | n/a                                                                                                                    |
| 143  | `LineString::triangles()` (sliding-window triangle iter, used by Visvalingam–Whyatt)         | Marginal — port currently inlines the loop inside `simplify_vw_line_string`. Could be unified but not in roadmap text. |
| 171  | `Polygon::empty()`                                                                           | **Yes** — explicitly named in roadmap text.                                                                            |
| 232  | `From<Point<T>>` / `From<Vec<Point<T>>>` for MultiPoint                                      | **Yes** — "MultiPoint From\*" in roadmap text.                                                                         |
| 383  | `AffineTransform::{scaled, translated, rotated, skewed, compose_many, inverse, is_identity}` | **Yes** — directly named in roadmap text.                                                                              |
| 394  | `contains_properly::ContainsProperly`                                                        | **Possibly** — fits "absorb the long tail" framing; not explicitly named.                                              |
| 432  | `simplify_vw::SimplifyVwIdx` / `SimplifyVwPreserve`                                          | Out — algorithm-completeness work, not trait/small-gap work.                                                           |
| 588  | rstar full surface (R\*-tree)                                                                | **No** — explicitly tagged "post-scope"; tracked under ms-18.                                                          |

### Triangle CCW ctor entry

The Triangle CCW ctor is **not** marked ⏳ in api-correspondence — its
row at line 210 is marked 🟡 (partial port) with a long note explaining
that the canonical constructor is semantically `unchecked_winding`. The
roadmap's "Triangle CCW ctor" line item is reflected there, not in the
⏳ legend.

### Note on out-of-scope predicate-trait deferral

The pairwise predicates (Contains/Covers/Intersects) are **not marked
⏳** in api-correspondence — they are ✅ as free-function ports
(`api-correspondence.md:393, 400, 408`). The "unify into traits" goal
of ms-16 is therefore an additive trait surface over already-ported
behaviour, not a port of net-new functionality.

---

## 9. Test count baseline

### File-type breakdown under `mbt/package/geo-mbt/src/`

- `*_test.mbt` (blackbox): 4 files
  - `robust/incircle_test.mbt`, `robust/orient2d_test.mbt`,
    `rtree/rtree_test.mbt`, plus all 14 `*_bench_test.mbt`.
- `*_wbtest.mbt` (whitebox): 1 file (`geo/2d/area_wbtest.mbt`).
- `*_bench_test.mbt`: 14 files (in `geo/2d/`, `robust/`, `rtree/`).
- `*_test.mbt.md` / `*.mbt.md` (markdown doctests): 49 files
  (every algorithm + every `type/` struct).

Total `*_test.mbt` + `*_wbtest.mbt` + `*_bench_test.mbt` = **19 files**
(`/tmp/ms16_testfiles.txt`).

### Test-case count

`grep -rEc '^\s*test\s' src/ --include='*.mbt' --include='*.mbt.md'`
yielded **429 test/bench cases** across 65 files with at least one match.

Top contributors (≥10 cases):

| Cases | File                                        |
| ----- | ------------------------------------------- |
| 32    | `geo/2d/type/line_string_test.mbt.md`       |
| 21    | `geo/2d/type/geometry_test.mbt.md`          |
| 20    | `geo/2d/type/coord_test.mbt.md`             |
| 19    | `geo/2d/type/rect_test.mbt.md`              |
| 18    | `geo/2d/type/point_test.mbt.md`             |
| 18    | `geo/2d/type/line_test.mbt.md`              |
| 17    | `geo/2d/type/polygon_test.mbt.md`           |
| 15    | `geo/2d/area.mbt.md`                        |
| 13    | `geo/2d/type/multi_line_string_test.mbt.md` |
| 11    | `geo/2d/vector_ops.mbt.md`                  |
| 11    | `geo/2d/property_test.mbt.md`               |
| 11    | `geo/2d/intersects.mbt.md`                  |
| 10    | `geo/2d/affine_transform.mbt.md`            |

The phase-1 baseline noted in `roadmap-progress.yaml:145` was "174 tests
passing"; the current ~429 figure includes bench tests and the doctest
migration (~3a4914d) that absorbed `traits_test.mbt`. Net regression
target for ms-16: maintain ≥429 cases while adding the new trait-impl
sweeps + small-gap unit tests.

---

## Source revision pinned in api-correspondence.md

`api-correspondence.md:18-22`:

| Library     | Version | Commit                                   | Date       |
| ----------- | ------- | ---------------------------------------- | ---------- |
| `geo`       | 0.33.1  | f34ee562db2a843037fb865d354b82a521cd9796 | 2026-04-29 |
| `geo-types` | 0.7.19  | f34ee562db2a843037fb865d354b82a521cd9796 | 2026-04-29 |
| `robust`    | 1.2.0   | 654f34cb8cdb3ae21bf59ef3472f92652942cd74 | 2025-05-09 |

All upstream snippets in this report were quoted from those snapshots
under `~/proj/geo/`.
