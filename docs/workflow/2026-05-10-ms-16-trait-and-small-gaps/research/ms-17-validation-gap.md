# ms-17 Validation Gap Analysis — RingRole + Coord/Ring Indices

**Date**: 2026-05-10
**Milestone**: `ms-17-validation-completion` ("Validation Completion — RingRole + indices")
**Status**: `planned` (per `roadmap-progress.yaml` L163–171)
**Upstream commit**: `f34ee562db2a843037fb865d354b82a521cd9796` (matches `api-correspondence.md` §1)
**Upstream version**: `geo` 0.33.1 (matches `api-correspondence.md` §1, `Cargo.toml` L3)

---

## 1. Current port implementation (`mbt/package/geo-mbt/src/geo/2d/validation.mbt`)

### 1.1 Structure

A single 121-line file. One enum + four functions. No per-geometry-type modules.

### 1.2 Types

```mbt
// validation.mbt:6-17
pub(all) enum ValidationProblem {
  TooFewPoints                // Linestring has fewer than 2 distinct coords
  RingNotClosed               // Polygon ring is not closed (first != last)
  RingTooFewPoints            // Polygon ring has fewer than 3 unique coords
  SelfIntersection            // Self-intersection detected (excluding endpoint touches)
  NonFiniteCoord              // One or more components contain non-finite coords
} derive(Eq, Debug)
```

Six flat variants (including `derive(Eq, Debug)` meta). **No fields** on any variant — every variant is a unit-like variant with zero payload.

### 1.3 Functions

| Function               | Signature                                                                           | Lines    | Role                                                                                                                                                                                                                                                                                                          |
| ---------------------- | ----------------------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `all_finite`           | `fn all_finite(coords: Array[@type.Coord]) -> Bool`                                 | L21–23   | Returns whether all coords in the array are finite (no NaN / Inf).                                                                                                                                                                                                                                            |
| `problem_if`           | `fn problem_if(flag: Bool, problem: ValidationProblem) -> Array[ValidationProblem]` | L28–37   | Helper — returns `[problem]` when `flag` holds, `[]` otherwise.                                                                                                                                                                                                                                               |
| `validate_ring`        | `fn validate_ring(ring: @type.LineString) -> Array[ValidationProblem]`              | L40–53   | Validates a single ring (exterior or interior). Checks `RingTooFewPoints` (< 4 coords), then `RingNotClosed`, then `NonFiniteCoord`.                                                                                                                                                                          |
| `validate_line_string` | `fn validate_line_string(ls: @type.LineString) -> Array[ValidationProblem]`         | L56–61   | Validates a non-ring linestring. Checks `TooFewPoints` (< 2 coords), then `NonFiniteCoord`.                                                                                                                                                                                                                   |
| `validation_problems`  | `pub fn validation_problems(g: @type.Geometry) -> Array[ValidationProblem]`         | L66–115  | The public entry point. Match on `Geometry` variant; for `Point`/`Line`/`Rect`/`Triangle` checks only `NonFiniteCoord`; for `LineString` delegates to `validate_line_string`; for `Polygon` delegates to `validate_ring` on exterior + all interiors; for `Multi*`/`GeometryCollection` fans out recursively. |
| `is_valid`             | `pub fn is_valid(g: @type.Geometry) -> Bool`                                        | L119–121 | Returns whether there are zero problems.                                                                                                                                                                                                                                                                      |

### 1.4 Key observations

- **No `RingRole`**: When validating a Polygon, exterior and interior rings are processed the same way (both go through `validate_ring`), and the resulting problems carry no information about which ring produced them (L73–80).
- **No coord index**: `NonFiniteCoord` is a unit variant with no payload — it does not report _which_ coordinate index within a ring/linestring is non-finite.
- **No ring index**: Interior rings are iterated with `flat_map` and their problems are concatenated into a flat `Array[ValidationProblem]`. There is no way to tell whether a `RingTooFewPoints` or `RingNotClosed` came from ring 0, ring 1, etc.
- **Missing validation checks**: Several upstream checks are entirely absent (see §3).

---

## 2. Upstream validation implementation (`~/proj/geo/georust-geo/geo/src/algorithm/validation/`)

### 2.1 Architecture

The upstream uses a **per-geometry-type error enum** design layered under a `Validation` trait. The directory contains 14 source files + 1 test file:

```
mod.rs                    — trait Validation, RingRole, GeometryIndex, CoordIndex
coord.rs                  — InvalidCoord (NonFinite)
point.rs                  — InvalidPoint (NonFiniteCoord)
line.rs                   — InvalidLine (IdenticalCoords, NonFiniteCoord(CoordIndex))
line_string.rs            — InvalidLineString (TooFewPoints, NonFiniteCoord(CoordIndex))
polygon.rs                — InvalidPolygon (6 variants, see below)
multi_point.rs            — InvalidMultiPoint (InvalidPoint(GeometryIndex, InvalidPoint))
multi_line_string.rs      — InvalidMultiLineString (InvalidLineString(GeometryIndex, InvalidLineString))
multi_polygon.rs          — InvalidMultiPolygon (3 variants, see below)
rect.rs                   — InvalidRect (NonFiniteCoord(CoordIndex))
triangle.rs               — InvalidTriangle (NonFiniteCoord(CoordIndex), IdenticalCoords(CoordIndex,CoordIndex), CollinearCoords)
geometry.rs               — InvalidGeometry (sum type of all per-type errors)
geometry_collection.rs    — InvalidGeometryCollection (InvalidGeometry(GeometryIndex, Box<InvalidGeometry>))
utils.rs                  — Shared helpers (check_coord_is_not_finite, check_too_few_points, robust_check_points_are_collinear, linestring_has_self_intersection)
tests.rs                  — JTS + GDAL validation test cases
```

### 2.2 Shared index types (`mod.rs` L104–125)

```rust
// mod.rs:104-108
pub enum RingRole {
    Exterior,
    Interior(usize),
}

// mod.rs:120-121
pub struct GeometryIndex(pub usize);

// mod.rs:124-125
pub struct CoordIndex(pub usize);
```

### 2.3 `Validation` trait (`mod.rs` L62–101)

```rust
// mod.rs:62-101
pub trait Validation {
    type Error: std::error::Error;
    fn is_valid(&self) -> bool { ... }
    fn validation_errors(&self) -> Vec<Self::Error> { ... }
    fn check_validation(&self) -> Result<(), Self::Error> { ... }
    fn visit_validation<T>(
        &self,
        handle_validation_error: Box<dyn FnMut(Self::Error) -> Result<(), T> + '_>,
    ) -> Result<(), T>;
}
```

Key design point: `visit_validation` takes a closure that can short-circuit on the first error (`check_validation`) or collect all errors (`validation_errors`). Each geometry type implements `Validation` with its own `type Error`.

### 2.4 Full `InvalidPolygon` enum (`polygon.rs` L16–30)

```rust
// polygon.rs:17-30
pub enum InvalidPolygon {
    TooFewPointsInRing(RingRole),
    SelfIntersection(RingRole),
    NonFiniteCoord(RingRole, CoordIndex),
    InteriorRingNotContainedInExteriorRing(RingRole),
    IntersectingRingsOnALine(RingRole, RingRole),
    IntersectingRingsOnAnArea(RingRole, RingRole),
}
```

### 2.5 Other per-type error enums

**`InvalidLineString`** (`line_string.rs` L7–11):

```rust
pub enum InvalidLineString {
    TooFewPoints,
    NonFiniteCoord(CoordIndex),
}
```

**`InvalidLine`** (`line.rs` L7–12):

```rust
pub enum InvalidLine {
    IdenticalCoords,
    NonFiniteCoord(CoordIndex),
}
```

**`InvalidTriangle`** (`triangle.rs` L7–13):

```rust
pub enum InvalidTriangle {
    NonFiniteCoord(CoordIndex),
    IdenticalCoords(CoordIndex, CoordIndex),
    CollinearCoords,
}
```

**`InvalidPoint`** (`point.rs` L7–9):

```rust
pub enum InvalidPoint {
    NonFiniteCoord,
}
```

**`InvalidRect`** (`rect.rs` L7–10):

```rust
pub enum InvalidRect {
    NonFiniteCoord(CoordIndex),
}
```

**`InvalidMultiPoint`** (`multi_point.rs` L8–10):

```rust
pub enum InvalidMultiPoint {
    InvalidPoint(GeometryIndex, InvalidPoint),
}
```

**`InvalidMultiLineString`** (`multi_line_string.rs` L8–11):

```rust
pub enum InvalidMultiLineString {
    InvalidLineString(GeometryIndex, InvalidLineString),
}
```

**`InvalidMultiPolygon`** (`multi_polygon.rs` L12–19):

```rust
pub enum InvalidMultiPolygon {
    InvalidPolygon(GeometryIndex, InvalidPolygon),
    ElementsOverlaps(GeometryIndex, GeometryIndex),
    ElementsTouchOnALine(GeometryIndex, GeometryIndex),
}
```

**`InvalidGeometryCollection`** (`geometry_collection.rs` L8–10):

```rust
pub enum InvalidGeometryCollection {
    InvalidGeometry(GeometryIndex, Box<InvalidGeometry>),
}
```

**`InvalidGeometry`** (`geometry.rs` L14–26):

```rust
pub enum InvalidGeometry {
    InvalidPoint(InvalidPoint),
    InvalidLine(InvalidLine),
    InvalidLineString(InvalidLineString),
    InvalidPolygon(InvalidPolygon),
    InvalidMultiPoint(InvalidMultiPoint),
    InvalidMultiLineString(InvalidMultiLineString),
    InvalidMultiPolygon(InvalidMultiPolygon),
    InvalidGeometryCollection(InvalidGeometryCollection),
    InvalidRect(InvalidRect),
    InvalidTriangle(InvalidTriangle),
}
```

**`InvalidCoord`** (`coord.rs` L6–9):

```rust
pub enum InvalidCoord {
    NonFinite,
}
```

### 2.6 Upstream validation checks performed (by geometry type)

| Geometry Type        | Checks Performed                                                                                                                                                                                                                                                                                | File:Line                      |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| `Coord`              | Non-finite coord                                                                                                                                                                                                                                                                                | `coord.rs:29`                  |
| `Point`              | Non-finite coord                                                                                                                                                                                                                                                                                | `point.rs:29`                  |
| `Line`               | Non-finite start/end coord (with CoordIndex), identical start/end                                                                                                                                                                                                                               | `line.rs:37–45`                |
| `LineString`         | Too few distinct points, non-finite coord (with CoordIndex)                                                                                                                                                                                                                                     | `line_string.rs:41–49`         |
| `Polygon`            | Too few points in ring (per ring + RingRole), self-intersection (per ring + RingRole), non-finite coord (per ring + RingRole + CoordIndex), interior not contained in exterior (DE-9IM relate), rings intersect on a line / area (DE-9IM relate, interior-vs-exterior and interior-vs-interior) | `polygon.rs:64–168`            |
| `MultiPoint`         | Each point validated (with GeometryIndex)                                                                                                                                                                                                                                                       | `multi_point.rs:32–39`         |
| `MultiLineString`    | Each line_string validated (with GeometryIndex)                                                                                                                                                                                                                                                 | `multi_line_string.rs:33–39`   |
| `MultiPolygon`       | Each polygon validated (with GeometryIndex), elements must not overlap, elements touch only at points (DE-9IM relate)                                                                                                                                                                           | `multi_polygon.rs:51–77`       |
| `Rect`               | Non-finite min/max corner (with CoordIndex)                                                                                                                                                                                                                                                     | `rect.rs:32–37`                |
| `Triangle`           | Non-finite coords (with CoordIndex), identical coords (with CoordIndex pairs), collinear coords                                                                                                                                                                                                 | `triangle.rs:42–85`            |
| `Geometry`           | Delegates to per-type impl                                                                                                                                                                                                                                                                      | `geometry.rs:69–100`           |
| `GeometryCollection` | Each geometry validated (with GeometryIndex)                                                                                                                                                                                                                                                    | `geometry_collection.rs:34–43` |

---

## 3. Gap analysis: port vs. upstream

### 3.1 Summary table

| Gap                                                                                                 | Port status                                                                                                                | Upstream status                                                                                                             | Severity                                       |
| --------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| **RingRole** (`Exterior` / `Interior(usize)`)                                                       | **Missing**. All ring problems are unit variants (no payload).                                                             | All polygon-level errors include `RingRole` to distinguish exterior vs. interior and which interior index.                  | High                                           |
| **CoordIndex** in `NonFiniteCoord`                                                                  | **Missing**. `NonFiniteCoord` is a unit variant — no index.                                                                | Every `NonFiniteCoord` variant carries `CoordIndex(usize)` identifying which coordinate is problematic.                     | Medium                                         |
| **GeometryIndex** in multi-geometries                                                               | **Missing**. Multi\* validation fans out via `flat_map` and loses positional info.                                         | MultiPoint/MultiLineString/MultiPolygon/GeometryCollection wrap per-element errors with `GeometryIndex(usize)`.             | Medium                                         |
| Per-geometry error types                                                                            | **Missing**. Single flat enum for all geometry types.                                                                      | Each geometry type has its own error enum (11 distinct types, see §2.4–2.5).                                                | Low (design choice)                            |
| `Validation` trait / `visit_validation` pattern                                                     | **Missing**. Only free functions.                                                                                          | Trait-based with `visit_validation` enabling short-circuit (`check_validation`) or collection (`validation_errors`).        | Low (MoonBit may adopt host-language patterns) |
| `InvalidLine::IdenticalCoords`                                                                      | **Missing**. The port only checks `NonFiniteCoord` for `Line`.                                                             | Checks both non-finite coords (with CoordIndex) and identical start/end.                                                    | Medium                                         |
| `InvalidTriangle::{IdenticalCoords, CollinearCoords}`                                               | **Missing**. The port only checks `NonFiniteCoord` for `Triangle`.                                                         | Checks non-finite coords, identical coords pairs, and collinearity (using robust `orient2d`).                               | Medium                                         |
| `InvalidRect::NonFiniteCoord(CoordIndex)`                                                           | **Missing coord index**. The port checks `NonFiniteCoord` but as a unit variant.                                           | Checks non-finite with coord index (0=min, 1=max).                                                                          | Low                                            |
| **Polygon interior containment** (`InteriorRingNotContainedInExteriorRing`)                         | **Missing entirely**.                                                                                                      | Validates each interior ring is fully contained within the exterior (using DE-9IM relate with PreparedGeometry caching).    | High                                           |
| **Polygon ring-ring intersection checks** (`IntersectingRingsOnALine`, `IntersectingRingsOnAnArea`) | **Missing entirely**.                                                                                                      | Validates that exterior-interior and interior-interior ring pairs do not intersect on a line or area (using DE-9IM relate). | High                                           |
| **MultiPolygon element overlap/touch checks** (`ElementsOverlaps`, `ElementsTouchOnALine`)          | **Missing entirely**.                                                                                                      | Validates that constituent polygons do not overlap (2D intersection) or touch on a line (1D intersection).                  | High                                           |
| `check_too_few_points` dedup behavior                                                               | **Different**. Port counts raw coords (< 4 for ring); upstream counts only distinct coords (via `remove_repeated_points`). | Upstream uses `remove_repeated_points()` to count only distinct points (`utils.rs:32–38`).                                  | Medium                                         |
| `SelfIntersection` check                                                                            | **Missing entirely**. Variant exists in enum but has no detector.                                                          | Uses `utils::linestring_has_self_intersection()` which checks all segment-pair intersections (`utils.rs:40–55`).            | High                                           |
| JTS/GDAL test suite                                                                                 | **Missing**.                                                                                                               | Upstream has 272 lines of test cases ported from JTS and GDAL validity documentation (`tests.rs`).                          | Medium                                         |

### 3.2 Specific code comparison: `NonFiniteCoord`

**Port** (`validation.mbt:16`):

```mbt
/// One or more components contain non-finite (NaN / infinite) coordinates.
NonFiniteCoord
```

Unit variant — no ring role, no coord index.

**Upstream** (`polygon.rs:23`):

```rust
/// One of the Polygon's coordinates is non-finite.
NonFiniteCoord(RingRole, CoordIndex),
```

Similarly for `InvalidLineString::NonFiniteCoord(CoordIndex)` (`line_string.rs:11`), `InvalidLine::NonFiniteCoord(CoordIndex)` (`line.rs:12`), `InvalidTriangle::NonFiniteCoord(CoordIndex)` (`triangle.rs:9`), `InvalidRect::NonFiniteCoord(CoordIndex)` (`rect.rs:9`).

### 3.3 Specific code comparison: ring identification in Polygon validation

**Port** (`validation.mbt:73–80`):

```mbt
@type.Geometry::Polygon(p) => {
  let exterior_problems = validate_ring(p.exterior())
  let interior_problems = p
    .interiors()
    .iter()
    .flat_map(fn(r) { validate_ring(r).iter() })
    .collect()
  [..exterior_problems, ..interior_problems]
}
```

Problems from interior rings are flattened into the same `Array[ValidationProblem]` as exterior problems — the caller cannot distinguish which ring produced which problem.

**Upstream** (`polygon.rs:70–99`):

```rust
for (ring_idx, ring) in std::iter::once(self.exterior())
    .chain(self.interiors().iter())
    .enumerate()
{
    let ring_role = if ring_idx == 0 {
        RingRole::Exterior
    } else {
        RingRole::Interior(ring_idx - 1)
    };
    // ...
    handle_validation_error(InvalidPolygon::TooFewPointsInRing(ring_role))?;
    handle_validation_error(InvalidPolygon::SelfIntersection(ring_role))?;
    for (coord_idx, coord) in ring.0.iter().enumerate() {
        if utils::check_coord_is_not_finite(coord) {
            handle_validation_error(InvalidPolygon::NonFiniteCoord(
                ring_role,
                CoordIndex(coord_idx),
            ))?;
        }
    }
}
```

Every problem is tagged with the specific `RingRole` and, for `NonFiniteCoord`, the specific `CoordIndex`.

### 3.4 Specific code comparison: `SelfIntersection` detection

**Port**: The `SelfIntersection` variant exists (`validation.mbt:13–14`) **but is never produced** — there is no code in the file that returns `SelfIntersection`. The variant is defined but unreachable in the current implementation.

**Upstream** (`utils.rs:40–55`):

```rust
pub(crate) fn linestring_has_self_intersection<F: GeoFloat>(geom: &LineString<F>) -> bool {
    for (i, line) in geom.lines().enumerate() {
        for (j, other_line) in geom.lines().enumerate() {
            if i != j
                && line.intersects(&other_line)
                && line.start != other_line.end
                && line.end != other_line.start
            {
                return true;
            }
        }
    }
    false
}
```

Called from `polygon.rs:88–89` for each ring. The port lacks this check entirely.

### 3.5 Specific code comparison: interior containment and ring-ring intersection

**Upstream** (`polygon.rs:102–167`):

```rust
let prepared_exterior = PreparedGeometry::from(&polygon_exterior);
for (interior_1_idx, interior_1) in self.interiors().iter().enumerate() {
    let ring_role_1 = RingRole::Interior(interior_1_idx);
    let prepared_interior_1 = PreparedGeometry::from(&interior_1_as_poly);
    let exterior_vs_interior = prepared_exterior.relate(&prepared_interior_1);
    if !exterior_vs_interior.is_contains() {
        // InteriorRingNotContainedInExteriorRing
    }
    if exterior_vs_interior.get(OnBoundary, OnBoundary) == OneDimensional {
        // IntersectingRingsOnALine (exterior vs interior)
    }
    for (interior_2_idx, interior_2) in self.interiors().iter().enumerate().skip(interior_1_idx + 1) {
        // IntersectingRingsOnAnArea / IntersectingRingsOnALine (interior vs interior)
    }
}
```

These checks require DE-9IM `relate` and `PreparedGeometry`, which are both deferred in the port (Phase 2 milestones ms-20, ms-18). This means the interior containment and ring intersection checks **fundamentally depend on ms-18 (R\*-tree) + ms-20 (DE-9IM)**, and ms-17 depends on ms-15 only — ms-17 will need to decide whether to implement a light-weight version or to decouple the enum shape from the deep relational checks.

---

## 4. Upstream geo version verification

| Check          | Expected                                   | Actual                                     | Match |
| -------------- | ------------------------------------------ | ------------------------------------------ | ----- |
| Crate name     | `geo`                                      | `geo`                                      | ✓     |
| Crate version  | `0.33.1`                                   | `0.33.1` (`Cargo.toml` L3)                 | ✓     |
| Commit hash    | `f34ee562db2a843037fb865d354b82a521cd9796` | `f34ee562db2a843037fb865d354b82a521cd9796` | ✓     |
| Commit message | —                                          | `chore: Unpin earcut version (#1533)`      | —     |

**Result**: The cloned reference repo at `~/proj/geo/georust-geo/` is at the exact same commit as recorded in `api-correspondence.md`.

---

## 5. api-correspondence.md validation entries

There is exactly **one** entry related to validation (L435):

```
| `validation::Validation` + `RingRole` / `Invalid*` | `is_valid(Geometry)`, `validation_problems(Geometry)` + flattened `ValidationProblem` enum | `validation_test.mbt` |  | 🟡 (errors flattened, no `RingRole` / indices) |
```

The status is `🟡` (partial port) with the note "errors flattened, no `RingRole` / indices" — this is precisely what ms-17 is scoped to fix.

---

## 6. Summary — Three Main Gaps

1. **`ValidationProblem` enum carries zero payload (no RingRole, no CoordIndex, no GeometryIndex)**. Every upstream error variant for Polygon includes `RingRole` to identify which ring (exterior or interior-N) had the problem. Every `NonFiniteCoord` carries `CoordIndex(usize)`. Multi-geometry errors wrap inner errors with `GeometryIndex(usize)`. The port's unit variants lose all positional information — the caller cannot distinguish which ring, which coordinate, or which sub-geometry is invalid.

2. **Five major validation checks are entirely absent** from the port: (a) self-intersection detection per ring (variant exists but is never produced), (b) interior-ring containment within exterior ring, (c) ring-ring intersection on a line/area, (d) multi-polygon element overlap/touch, and (e) per-type checks for `Line` (identical coords) and `Triangle` (identical coords, collinearity). Checks (b)–(d) fundamentally require DE-9IM `relate` + `PreparedGeometry`, which are scoped to ms-18 and ms-20 respectively — ms-17 may need to shape the enum types now and defer the deep relational checks.

3. **The port uses a single flat `ValidationProblem` enum** shared across all geometry types, while upstream uses 11 per-geometry-type error enums under a `Validation` trait with `visit_validation` allowing short-circuit on first error or collection of all errors. The port could keep the flat-enum design but must add field payloads and per-type problem variants to close the gap; a full trait-based redesign is a lower-priority concern.
