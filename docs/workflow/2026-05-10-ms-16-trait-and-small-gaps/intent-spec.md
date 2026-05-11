# Intent Spec — ms-16 Trait Surface Expansion + Small ⏳ Items

Cycle: `2026-05-10-ms-16-trait-and-small-gaps`
Roadmap: `geo-mbt` / milestone `ms-16-trait-and-small-gaps`
Branch: `cobalt-ocotillo` (per Phase 1 single-branch policy; per-milestone PR split deferred to Phase 2 review)

## Background

Phase 1 (ms-01〜ms-15) closed with 174 → 411 tests across `mbt/package/geo-mbt`. The pairwise predicates `contains` / `covers` / `intersects` were ported as `<op>_<a>_<b>(a, b)` free functions plus a single `<op>_geometry(Geometry, Geometry)` enum dispatcher. No predicate trait exists. A long tail of small ⏳ items remains in `api-correspondence.md`.

## Goal

Provide a **constraint-only** trait surface for the four pairwise predicate operations (`Contains` / `Covers` / `Intersects` / `Within`) and absorb the explicitly-named small ⏳ items.

The trait surface is **constraint-only** (per user policy, see memory `project_geo_mbt_roadmap.md` post-scope priority #2): it gives generic functions a uniform method to constrain on, without rewriting algorithm internals. Every trait method delegates to the existing free function.

## In-scope items

### A. Pairwise predicate traits

Add four single-method, `Self`-on-left, `Geometry`-on-right traits to `geo/2d/type/traits.mbt`. Each has one method:

```mbt
pub(open) trait ContainsGeometry {
  contains_geometry(Self, Geometry) -> Bool
}
pub(open) trait CoversGeometry {
  covers_geometry(Self, Geometry) -> Bool
}
pub(open) trait IntersectsGeometry {
  intersects_geometry(Self, Geometry) -> Bool
}
pub(open) trait WithinGeometry {
  within_geometry(Self, Geometry) -> Bool
}
```

Implemented for: `Geometry`, `Polygon`, `MultiPolygon`, `Rect`, `Point`, `Line`, `LineString`, `MultiLineString`, `MultiPoint`, `Triangle`, `GeometryCollection`. Each impl wraps `self` into the corresponding `Geometry` variant and dispatches to the existing free function `<op>_geometry`.

### B. Polygon::empty

Add `Polygon::empty() -> Polygon` factory in `type/polygon.mbt` mirroring `MultiPolygon::empty`. Delete the ⏳ marker on `api-correspondence.md:171`.

### C. Triangle CCW constructor

Add `Triangle::ccw(v0, v1, v2) -> Triangle` factory in `type/triangle.mbt` that uses `@robust.orient2d` to detect CW input and swap the last two vertices to enforce CCW winding. The existing `Triangle::Triangle` canonical ctor remains as `unchecked_winding`-equivalent. Update the partial-port note at `api-correspondence.md:208-211`.

### D. AffineTransform missing methods

Add to `geo/2d/affine_transform.mbt`:

| Method                                                                | Body                                                             |
| --------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `inverse(Self) -> Self?`                                              | Determinant + 2×2 inversion; return `None` when det == 0         |
| `is_identity(Self) -> Bool`                                           | Exact-equality vs identity matrix                                |
| `compose_many(Self, Array[Self]) -> Self`                             | Fold via existing `compose`                                      |
| `scaled(Self, xfact: Double, yfact: Double, origin: Coord) -> Self`   | Wither: `self.compose(Self::scale_around(xfact, yfact, origin))` |
| `translated(Self, xoff: Double, yoff: Double) -> Self`                | Wither                                                           |
| `rotated(Self, degrees: Double, origin: Coord) -> Self`               | Wither                                                           |
| `skewed(Self, xs_deg: Double, ys_deg: Double, origin: Coord) -> Self` | Wither                                                           |

Origin-aware base factories needed for the witherers:

| Method                                        | Note                                                      |
| --------------------------------------------- | --------------------------------------------------------- |
| `scale_around(xfact, yfact, origin) -> Self`  | Conjugate translate(−origin) ∘ scale ∘ translate(+origin) |
| `rotate_around(degrees, origin) -> Self`      | Same conjugation                                          |
| `skew_around(xs_deg, ys_deg, origin) -> Self` | Same conjugation                                          |

The existing `rotate_origin` / `skew_origin` (rotate / skew **about (0, 0)**) remain as the no-conjugation primitives. Naming clarification: the old name `rotate_origin` keeps its meaning ("rotate about origin"), and we add `rotate_around(degrees, origin)` for arbitrary pivots. Same for skew. `scale_xy` similarly stays as the pure-axis version; `scale_around` is added.

Remove the ⏳ at `api-correspondence.md:383`.

### E. MultiPoint From-style helpers

Add to `type/multi_point.mbt`:

| Helper                                                        | Body                   |
| ------------------------------------------------------------- | ---------------------- |
| `MultiPoint::from_point(p: Point) -> MultiPoint`              | length-1 multipoint    |
| `MultiPoint::from_coord(c: Coord) -> MultiPoint`              | length-1 multipoint    |
| `MultiPoint::from_coords(coords: Array[Coord]) -> MultiPoint` | bulk Coord → Point map |

The `Vec<Point>` upstream variant is already covered by the canonical `MultiPoint::MultiPoint(Array[Point])` ctor. Remove the ⏳ at `api-correspondence.md:232`.

## Out-of-scope (explicit non-goals)

- Deeper trait designs that try to express `Contains[T]` parametrised over the right operand (verified impossible in MoonBit's trait system per memory `project_geo_mbt_roadmap.md`). The constraint-only `…_geometry(Self, Geometry)` shape is the agreed surface.
- DE-9IM `Relate` (deferred to ms-20).
- `ContainsProperly` (`api-correspondence.md:394` ⏳) — not enumerated in roadmap text; keep ⏳.
- `LineString::triangles()` helper (`api-correspondence.md:143` ⏳) — used only inside Visvalingam-Whyatt, kept inline in `simplify_vw`.
- `SimplifyVwIdx` / `SimplifyVwPreserve` (`api-correspondence.md:432` ⏳) — algorithm-completeness work, tracked separately.

## Acceptance criteria

1. `vp run --filter @totto2727/geo-mbt check` passes.
2. `vp run --filter @totto2727/geo-mbt test` passes with **≥ 429 cases** (existing baseline) plus added trait-impl sweeps and small-gap unit tests.
3. `moon info` produces a clean diff — every public addition is reflected in the `*.mbti` interface files.
4. `api-correspondence.md` no longer carries ⏳ on lines 171, 232, 383, and the Triangle 🟡 note at 208-211 is updated to record the new CCW ctor.
5. Existing free-function call sites (`contains_geometry`, etc.) remain valid; the new traits are additive only.

## Test plan summary

- Unit tests for each new factory / method in the corresponding `*.mbt.md` file.
- Trait-impl sweep: parametrised tests covering each (Self, other) pair already covered by the underlying free function, asserting equivalence with the free function.
- AffineTransform inverse: round-trip property `t.compose(t.inverse().unwrap()) ≈ identity`.
- AffineTransform `is_identity` exact-equality.
- Triangle CCW: feed both CW and CCW inputs; assert winding is CCW.

## Rollback

If any single area (A-E) hits an unexpected MoonBit-trait constraint, that area is dropped from the cycle and recorded as a follow-up ms-16-residual line in retrospective. The other areas land independently; the trait surface (A) is the only inter-dependent one.
