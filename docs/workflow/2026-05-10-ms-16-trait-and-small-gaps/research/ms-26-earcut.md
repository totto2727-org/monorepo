# ms-26 Earcut Triangulation — Port Research Report

**Date:** 2026-05-10
**Researcher:** Automated analysis
**Source crate:** `earcutr` v0.5.0 (`~/proj/geo/earcutr/`)
**Target:** `@totto2727/geo-mbt` — `src/earcut/` + `src/geo/2d/triangulate_earcut.mbt`

---

## 1. Source Files and Line Counts

| File | Lines | Role |
|------|-------|------|
| `src/lib.rs` | 1335 | **Main algorithm** — all core logic |
| `src/legacy.rs` | 124 | Utilities: `flatten()`, `deviation()`, debug dump |
| `src/tests.rs` | 729 | Unit tests (linked list, ear detection, etc.) |
| `tests/integration_test.rs` | 347 | 30 fixture-based area-verification tests |
| `benches/speedtest.rs` | 578 | Criterion benchmarks |
| `examples/main.rs` | 110 | Example runner |
| `fuzz/fuzz_targets/earcut.rs` | 12 | Fuzz harness |
| **Total** | **3235** | |

**Core algorithm to port: ~1335 lines** (`lib.rs`) + ~124 lines (`legacy.rs` for `flatten`/`deviation` if needed).

---

## 2. Dependencies

```toml
[dependencies]
itertools = "0.14"
num-traits = "0.2"

[dev-dependencies]
criterion = "0.5"
serde = "1.0.88"
serde_json = "1.0.107"
```

**Dependency mapping for MoonBit:**
- `itertools` — used only for `.tuples()` to iterate flat array in (x,y) pairs. MoonBit: manual index stepping.
- `num-traits` — used for `Float` trait bound + `num_traits::cast` for f64/i64 conversions. MoonBit: hardcode `Double` + `to_int()`/`to_double()`.
- `criterion`, `serde`, `serde_json` — dev-only, not needed.

---

## 3. Complete Public API

### 3.1 Main function

```rust
pub fn earcut<T: Float>(
    vertices: &[T],           // flat array: [x0, y0, x1, y1, x2, y2, ...]
    hole_indices: &[usize],   // indices of hole starts (in coordinate *pair* units)
    dims: usize,              // dimensions per vertex (2 for 2D, 3 for 3D)
) -> Result<Vec<usize>, Error>
```

### 3.2 Re-exported utility functions (from `legacy`)

```rust
pub fn flatten<T: Float + Display>(
    data: &Vec<Vec<Vec<T>>>
) -> (Vec<T>, Vec<usize>, usize)
// Input:  GeoJSON-like nested arrays [[[x,y],...], [[x,y],...]]
// Output: (flat_coords, hole_indices, dimensions)

pub fn deviation<T: Float + Display>(
    vertices: &[T],
    hole_indices: &[usize],
    dims: usize,
    triangles: &[usize],
) -> T
// Computes percentage area difference between polygon and triangulation.
// Used for correctness verification.
```

### 3.3 Public types

```rust
pub enum Error { Unknown }                    // implements Display + Error
pub trait Float: num_traits::float::Float {}  // blanket impl for all floats
pub struct LinkedLists<T: Float> { .. }       // pub struct, internal use
pub mod legacy;                               // re-exports flatten, deviation
```

### 3.4 Input Format (detailed)

`vertices` is a **flat** `[T]` slice. For a simple triangle with points (0,0), (1,0), (1,1):
```
vertices = [0.0, 0.0, 1.0, 0.0, 1.0, 1.0]
```

`hole_indices` contains the vertex **index** (in coordinate-pair units, not byte offsets) where each hole ring's data begins. For a square with one hole:
```
outer: (0,0), (10,0), (10,10), (0,10)   → indices 0..4
hole:  (2,2), (8,2), (8,8), (2,8)        → indices 4..8
vertices    = [0,0, 10,0, 10,10, 0,10, 2,2, 8,2, 8,8, 2,8]
hole_indices = [4]   // hole starts at vertex index 4
```

`dimensions` is the number of coordinates per vertex. Typically `2` for 2D. When `3`, the algorithm only uses the first 2 coords for topology; the third is carried through for indexing purposes.

### 3.5 Output Format

`Result<Vec<usize>, Error>` — flat array of triangle indices. Every 3 consecutive values form one triangle. Each index refers to a vertex pair in the original input (index 0 → `vertices[0..1]`, index 1 → `vertices[2..3]`, etc. when `dimensions == 2`).

Example output for the triangle above: `[1, 0, 2]`

---

## 4. Algorithm Structure

The algorithm is a direct port of [Mapbox earcut.js](https://github.com/mapbox/earcut) with David Eberly's hole-bridging algorithm. It uses a **4-pass** ear-clipping strategy on a **circular doubly-linked list**:

### 4.1 Entry Point: `earcut()`

```
earcut(vertices, hole_indices, dims)
  → validate input
  → linked_list() — build outer ring as doubly-linked list (enforce CCW)
  → eliminate_holes() — link each hole into the outer ring via find_hole_bridge()
  → If >=80 vertices: normalize coords, compute z-order curve, use earcut_linked_hashed()
  → Else: use earcut_linked_unhashed()
  → Return flat Vec<usize> of triangle indices
```

### 4.2 Four-Pass Ear Clipping

Both `earcut_linked_hashed` and `earcut_linked_unhashed` share a 4-pass strategy:

| PASS | Action on stall | Purpose |
|------|-----------------|---------|
| 0 | Try standard ear-clipping | Primary path — works for most inputs |
| 1 | `filter_points()` — remove colinear/duplicate vertices, retry PASS 0 | Clean up degenerate geometry |
| 2 | `cure_local_intersections()` — remove local self-intersections, retry PASS 0 | Handle self-touching polygons |
| 3 | `split_earcut()` — split along valid diagonal, recurse on halves | Handle complex non-earable polygons |

### 4.3 Key Functions

| Function | LOC | Role |
|----------|-----|------|
| `earcut()` | ~55 | Entry point, dispatches to either hashed/unhashed |
| `linked_list()` | ~8 | Builds doubly-linked list from flat coords |
| `add_contour()` | ~55 | Adds a ring (outer or hole) to the linked list, enforces winding order |
| `eliminate_holes()` | ~42 | Links all hole rings to the outer ring via bridges |
| `find_hole_bridge()` | ~70 | David Eberly's bridge-finding algorithm (ray from hole leftmost point) |
| `earcut_linked_hashed()` | ~47 | Main ear-clipping loop with z-order spatial hash |
| `earcut_linked_unhashed()` | ~42 | Main ear-clipping loop without spatial hash (for small polygons) |
| `is_ear_hashed()` | ~83 | **Most complex** — ear test using z-order for O(log n) spatial queries |
| `is_ear()` | ~14 | Simpler ear test — O(n) spatial queries |
| `cure_local_intersections()` | ~54 | Remove local self-intersections |
| `split_earcut()` | ~53 | Split polygon along valid diagonal, recurse |
| `split_bridge_polygon()` | ~29 | Connect or split linked lists via bridge node |
| `filter_points()` | ~35 | Remove colinear/duplicate vertices |
| `pseudo_intersects()` | ~14 | Check if two segments cross |
| `intersects_polygon()` | ~11 | Check if diagonal intersects any polygon edge |
| `locally_inside()` | ~18 | Check if diagonal is locally inside polygon |
| `middle_inside()` | ~10 | Ray-casting: is diagonal midpoint inside polygon? |
| `signed_area()` | ~8 | Signed area of a ring segment |
| `calc_invsize()` | ~6 | Compute inverse size for z-order normalization |
| `zorder()` | ~14 | Compute 64-bit Morton code for spatial hashing |
| `index_curve()` | ~20 | Interlink nodes in z-order for spatial queries |
| `sort_linked()` | ~58 | Simon Tatham's linked-list merge sort (on z-order) |

### 4.4 Internal Data Structures

```rust
struct Coord<T> { x: T, y: T }

struct LinkedListNode<T> {
    vertices_index: usize,           // index into original flat vertex array
    coord: Coord<T>,                 // x, y
    prev_linked_list_node_index: usize, // prev in ring
    next_linked_list_node_index: usize, // next in ring
    z: i32,                          // z-order curve value
    prevz_idx: usize,                // prev in z-order
    nextz_idx: usize,                // next in z-order
    is_steiner_point: bool,          // steiner point marker
    idx: usize,                      // self-index in nodes Vec
}

struct LinkedLists<T> {
    nodes: Vec<LinkedListNode<T>>,   // index 0 = NULL sentinel node
    invsize: T,                      // for z-order normalization
    min: Coord<T>, max: Coord<T>,    // bounding box
    usehash: bool,                   // whether to use z-order hashing
}
```

---

## 5. Geo Wrapper Analysis

Geo wraps earcut through the `earcut` crate v0.4.9 (not `earcutr`), but the algorithm is effectively the same (both are ports of Mapbox earcut.js). The geo wrapper (`geo/src/algorithm/triangulate_earcut.rs`, 314 lines) provides:

### Public trait: `TriangulateEarcut<T: CoordFloat>` on `Polygon<T>`

| Method | Returns | Description |
|--------|---------|-------------|
| `earcut_triangles()` | `Vec<Triangle<T>>` | Collect all triangles |
| `earcut_triangles_iter()` | `Iter<T>` | Lazy iterator |
| `earcut_triangles_raw()` | `RawTriangulation<T>` | Flat vertices + indices |

### `RawTriangulation<T>` struct
```rust
pub struct RawTriangulation<T: CoordFloat> {
    pub vertices: Vec<[T; 2]>,           // flat coords per vertex
    pub triangle_indices: Vec<usize>,    // every 3 = one triangle
}
```

### Wrapper Pipeline
1. `EarcutInput::from(&Polygon)` — flattens exterior + interiors into `Vec<[T;2]>`, tracks interior start indices (skipping redundant closing coord)
2. Calls `earcut.earcut(vertices, interior_indexes, &mut triangle_indices)`
3. Returns `RawTriangulation { vertices, triangle_indices }`

---

## 6. api-correspondence.md Entry

Line 443:
```
| `triangulate_earcut`, `triangulate_delaunay`, `triangulate_spade` | — | — | — | ⛔ |
```
All three triangulation modules are currently marked **out of scope (⛔)**. ms-26 would change `triangulate_earcut` from ⛔ → ✅.

---

## 7. Port Complexity Assessment

### 7.1 Effort Estimation

| Category | Estimate |
|----------|----------|
| Core algorithm (`lib.rs`) | ~1335 lines of Rust → ~1000-1200 lines of MoonBit |
| Public API + wrapper (`triangulate_earcut.mbt`) | ~250 lines (port of geo wrapper) |
| Unit tests | ~30-50 test cases |
| Documentation + doctests | inline |
| **Total estimated MoonBit code** | ~1500-1800 lines |
| **Estimated effort** | ~1 dev-workflow cycle (confirms milestone estimate) |

### 7.2 MoonBit Data Structures Needed

```moonbit
// Already exist in geo-mbt:
// - Triangle (type/geometry)
// - Polygon (type/geometry)
// - Coord (type/geometry)

// New structures for earcut internals:
struct CoordData { x : Double; y : Double }

struct Node {
  vertices_index : Int
  coord : CoordData
  prev : Int  // linked list index (0 = NULL sentinel)
  next : Int  // linked list index
  z : Int     // z-order value (-1 = uninitialized)
  prevz : Int
  nextz : Int
  is_steiner_point : Bool
  idx : Int   // self-index
}

struct LinkedLists {
  nodes : Array[Node]  // index 0 = NULL sentinel
  invsize : Double
  min_x : Double; min_y : Double
  max_x : Double; max_y : Double
  usehash : Bool
}

enum EarcutError {
  Unknown
}

struct RawTriangulation {
  vertices : Array[Array[Double]]  // [[x,y], ...]
  triangle_indices : Array[Int]
}
```

### 7.3 Tricky Algorithm Details

1. **Z-order curve hashing** (`zorder()` + `index_curve()` + `sort_linked()`) — The z-order spatial index is the most complex part, involving Morton code computation from 64-bit interleaved coordinates, bit manipulation, and a merge sort on a linked list. The `is_ear_hashed()` function uses this to achieve near-O(log n) ear checking. **Mitigation:** Skip the hashed path entirely for an initial port. The unhashed `is_ear()` (O(n) per ear check) works correctly for all inputs and the hashed path only exists for performance. The threshold is 80 vertices — polygons below this already use unhashed.

2. **`const PASS: usize` generic** — Rust uses compile-time generics for the pass number (0, 1, 2). MoonBit: replace with a regular `Int` parameter (runtime). No performance concern since this is just a branch predicate.

3. **Macros** (`next!`, `prev!`, `nextref!`, `prevref!`) — These are shorthand for `ll.nodes[ll.nodes[idx].next_linked_list_node_index]`. In MoonBit: inline the indexing directly (or use small helper functions).

4. **David Eberly's hole bridge** (`find_hole_bridge()`) — Complex geometric algorithm with floating-point edge cases. Uses `T::neg_infinity()` and `T::max_value()` which need direct MoonBit `Double` equivalents. Port carefully with tests from `integration_test.rs` (30 fixture files).

5. **Winding order enforcement** (`add_contour()`) — Outer ring must be CCW, holes CW. The signed area check handles this automatically, but colinear edge cases need testing. The algorithm iterates in different directions depending on winding, producing the same final CCW outer ring orientation.

6. **Split polygon recursion** (`split_earcut()`) — Recursion depth is bounded by polygon complexity, but very degenerate inputs could cause deep recursion. MoonBit supports recursion; no issue for typical geo polygons.

7. **Floating-point sentinel values** — The algorithm uses `T::max_value()` (for initial min) and `T::min_value()` (for initial max). In MoonBit, use `Double` constants: `Infinity`, `NegInfinity`, or the largest/smallest finite values. The Rust earcutr code also uses `T::neg_infinity()` in `find_hole_bridge`.

### 7.4 Key Porting Decisions

| Decision | Recommendation |
|----------|---------------|
| Z-order hashing | **Skip for initial port.** Use `is_ear()` (unhashed) only. Add hashing later as optimization if needed. This cuts ~200 lines of port complexity (`zorder`, `index_curve`, `sort_linked`, `is_ear_hashed`). |
| Generic `T: Float` vs `Double` | **Hardcode `Double`.** Consistent with geo-mbt design decisions (no `CoordNum` generics). |
| `const PASS` generic | **Replace with `Int` parameter.** Simpler, negligible runtime cost. |
| Error handling | **Use `EarcutError` enum.** The upstream only has `Unknown` variant; keep it simple. |
| `flatten()` utility | **Not needed as public API** if geo wrapper handles flattening (as geo does). Keep as internal helper if needed for test fixtures. |
| `deviation()` utility | **Useful for test correctness verification.** Port as a private test helper function. |
| Recursion (split_earcut) | **Direct translation** — MoonBit supports recursion natively. |
| Linked list sentinel | **Index 0 = NULL sentinel.** Keep the same design. MoonBit `Array[Node]` with a dummy node at index 0. |

### 7.5 Test Coverage Strategy

The integration tests (`tests/integration_test.rs`) test 30 fixture-based polygons from JSON files in `tests/fixtures/`. Each test verifies:
- Correct number of output triangles
- Area deviation between original polygon and triangulation < threshold

**For the MoonBit port:**
- Port the 30 fixture files as embedded test data arrays (or copy JSON files)
- Write equivalent area-deviation tests
- Also port unit tests from `src/tests.rs` covering: linked list ops, ear detection, signed area, point-in-triangle, intersection, hole bridging, local intersection curing, split earcut

---

## 8. Reference Material

- **Primary source:** `~/proj/geo/earcutr/src/lib.rs` (1335 lines)
- **Legacy utilities:** `~/proj/geo/earcutr/src/legacy.rs` (124 lines)
- **Unit tests:** `~/proj/geo/earcutr/src/tests.rs` (729 lines)
- **Integration tests:** `~/proj/geo/earcutr/tests/integration_test.rs` (347 lines)
- **Test fixtures:** `~/proj/geo/earcutr/tests/fixtures/` (30+ JSON files)
- **Geo wrapper:** `~/proj/geo/georust-geo/geo/src/algorithm/triangulate_earcut.rs` (314 lines)
- **Original JS algorithm:** [Mapbox earcut.js](https://github.com/mapbox/earcut)
- **Hole-bridging algorithm:** David Eberly, "Triangulation by Ear Clipping" ([pdf](https://www.geometrictools.com/Documentation/TriangulationByEarClipping.pdf))
- **Milestone doc:** `docs/roadmap/geo-mbt/milestones/ms-26-earcut-triangulation.md`
- **Roadmap progress:** `docs/roadmap/geo-mbt/roadmap-progress.yaml` (line 252)

---

## 9. Suggested File Layout in geo-mbt

```
src/earcut/
  earcut.mbt              # core algorithm (port of lib.rs)
  earcut_test.mbt          # unit tests (port of tests.rs)
  earcut_wbtest.mbt        # whitebox tests if needed

src/geo/2d/
  triangulate_earcut.mbt   # public API + Polygon trait (port of geo wrapper)
  triangulate_earcut_test.mbt   # integration tests
```

---

**Summary:** The earcutr crate is a ~1335-line Rust implementation of Mapbox's ear-clipping triangulation. The algorithm is well-documented, battle-tested (30+ fixture-based integration tests), and self-contained (only two dependencies, both easily replaced with stdlib equivalents). The port to MoonBit is estimated at **~1500-1800 lines** with the z-order hashing path deferred to reduce risk. The main challenges are the doubly-linked list data structure translation and the hole-bridging geometry algorithm. ms-26 has no dependencies on other Phase 2 milestones (only ms-15-validation-finalize), and is **fully independent** of i_overlay, Delaunay, and stitch.
