# 4. `rstar` ↔ `src/rtree/`

Port package: `totto2727/geo-mbt/rtree` (`src/rtree/pkg.generated.mbti`).
Originally added as a minimal bulk-loaded index; Phase 2 ms-18 expanded
it to a viable dynamic R\*-tree (insert / remove / locate / nearest /
iter / drain). The port still omits forced-reinsertion, condense-tree
on remove, best-first NN traversal, and tunable params — see "Deferred
items" below.

### 4.1 Types

| Rust upstream item                                                                      | MoonBit port                                                       | Status | Notes                                                                                          |
| --------------------------------------------------------------------------------------- | ------------------------------------------------------------------ | ------ | ---------------------------------------------------------------------------------------------- |
| `pub struct RTree<T, Params = DefaultParams>`                                           | `pub struct RTree[T] { root: Node[T]?, size: Int }`                | 🟡     | No tunable params; default fanout fixed                                                        |
| `pub trait RTreeObject` + `Envelope` assoc type                                         | `pub struct Entry[T] { bbox: Rect, value: T }` (explicit envelope) | 🟡     | Port carries the envelope alongside the value                                                  |
| `pub struct AABB<P>`                                                                    | (uses `@type.Rect`)                                                | ✅     | Reuses 2D rect                                                                                 |
| `pub trait Point`, `RTreeNum`, `PointExt`                                               | —                                                                  | ⛔     | Generic point machinery not needed                                                             |
| `pub trait Envelope`                                                                    | —                                                                  | ⛔     | Single concrete envelope                                                                       |
| `pub trait PointDistance`                                                               | —                                                                  | ⛔     | Hard-coded squared-distance to bbox                                                            |
| `pub trait RTreeParams`, `DefaultParams`, `InsertionStrategy`, `RStarInsertionStrategy` | — (fixed fanout / fixed insertion strategy)                        | ⛔     | Dynamic insert is exposed, but tunable params and R\*-specific reinsertion remain out of scope |
| `pub trait SelectionFunction`                                                           | —                                                                  | ⛔     |                                                                                                |
| `pub struct ParentNode`, `pub enum RTreeNode`                                           | `type Node[T]` (opaque)                                            | 🟡     | Internal-only — not exposed                                                                    |
| `iterators` module (`RTreeIterator`, `LocateIn*`, `DrainIterator`, …)                   | —                                                                  | ⛔     |                                                                                                |
| `mint` integration                                                                      | —                                                                  | ⛔     |                                                                                                |
| `primitives::{GeomWithData, ObjectRef, Rectangle, Line, PointWithData, CachedEnvelope}` | `Entry[T]` only                                                    | 🟡     |                                                                                                |

### 4.2 `RTree` methods

Upstream `RTree<T, P>` exposes ~46 public methods. Phase 2 ms-18
expanded the port surface from 5 to 13 methods (covers the static
**and** dynamic operations needed by ms-30 indexed algorithms and ms-31
clustering).

| Rust method                                                                                                                                                                                                             | MoonBit port                                                        | Status                                                               |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `RTree::new()`                                                                                                                                                                                                          | `RTree::new() -> Self[T]`                                           | ✅ (added in ms-18)                                                  |
| `RTree::bulk_load(elements: Vec<T>) -> Self`                                                                                                                                                                            | `RTree::bulk_load(Array[Entry[T]]) -> Self[T]`                      | ✅                                                                   |
| `RTree::size(&self) -> usize`                                                                                                                                                                                           | `RTree::size(Self[T]) -> Int`                                       | ✅                                                                   |
| (no direct rstar equiv — derived from `size == 0`)                                                                                                                                                                      | `RTree::is_empty(Self[T]) -> Bool`                                  | ✅                                                                   |
| `RTree::insert(&mut self, t: T)`                                                                                                                                                                                        | `RTree::insert(Self[T], Entry[T]) -> Unit`                          | 🟡 (ms-18; forced-reinsertion deferred)                              |
| `RTree::remove(&mut self, t: &T) -> Option<T>`                                                                                                                                                                          | `RTree::remove(Self[T], Entry[T]) -> T?` (`T : Eq`)                 | 🟡 (ms-18; condense-tree pass deferred)                              |
| `RTree::locate_at_point(&self, p)` (iter)                                                                                                                                                                               | `RTree::locate_at_point(Self[T], Coord) -> Array[T]`                | ✅ (ms-18 — returns Array)                                           |
| `RTree::locate_within_distance(&self, p, d²)` (iter)                                                                                                                                                                    | `RTree::locate_within_distance(Self[T], Coord, Double) -> Array[T]` | ✅ (ms-18)                                                           |
| `RTree::nearest_neighbor(&self, p) -> Option<&T>`                                                                                                                                                                       | `RTree::query_nearest(Self[T], Coord) -> T?`                        | ✅                                                                   |
| `RTree::nearest_neighbor_iter(&self, p)` (k-NN)                                                                                                                                                                         | `RTree::nearest_neighbors(Self[T], Coord, Int?) -> Array[T]`        | 🟡 (ms-18; brute-force collect-sort instead of best-first traversal) |
| `RTree::iter(&self)` / `iter_mut`                                                                                                                                                                                       | `RTree::iter(Self[T]) -> Iter[T]`                                   | ✅ (ms-18 — depth-first leaf walk)                                   |
| `RTree::drain(&mut self)` (iter)                                                                                                                                                                                        | `RTree::drain(Self[T]) -> Array[T]`                                 | ✅ (ms-18 — returns Array)                                           |
| `RTree::locate_in_envelope_intersecting(&self, env)` (returns iterator)                                                                                                                                                 | `RTree::query_rect_intersection(Self[T], Rect) -> Array[T]`         | 🟡 (returns `Array`, not iterator)                                   |
| `bulk_load_with_params`, `locate_all_at_point*`, `nearest_neighbor_with_distance_2`, `intersection_candidates_with_other_tree`, `locate_with_selection_function*`, `drain_with_selection_function*`, `contains`, `root` | —                                                                   | ⏳ (post-Phase-2; can be added without surface changes)              |
| `Entry::Entry(Rect, T)` (port canonical constructor)                                                                                                                                                                    | `Entry::Entry(Rect, T) -> Entry[T]`                                 | ✅ (no direct rstar counterpart)                                     |

#### Deferred items (marked `// TODO ms-18-followup`)

- Forced-reinsertion on overflow (the R\* in R\*-tree) — port currently does pure split.
- Overlap-enlargement at the leaf level inside `choose_subtree` — port uses area-enlargement only.
- Condense-tree pass on `remove` — port allows leaves to shrink and drops empty leaves but does not reinsert orphan subtrees.
- Best-first nearest-neighbour traversal via priority queue — port uses brute-force collect-sort.

### 4.3 Tests / benches

`rtree/rtree_test.mbt` — 16 cases:

- `empty RTree`, `single entry intersection`, `many entries: rectangular query`
- `query_nearest: empty returns None`, `query_nearest: returns the nearest entry`
- `RTree::new: empty tree`, `insert: size increments per item`, `insert N items, iter yields N`
- `insert with splits keeps query results correct`, `remove existing returns Some, size decrements`
- `remove non-existent returns None, size unchanged`, `remove all leaves empty tree`
- `remove then reinsert keeps queries correct`
- `locate_at_point: finds overlapping rects`, `locate_within_distance: finds entries within radius`
- `nearest_neighbors: returns elements in distance order`, `nearest_neighbors: respects k limit`
- `drain: returns all and leaves empty`
- `exhaustive verification: query against all entries`

`rtree/rtree_bench_test.mbt` — 4 cases:

- `bench: RTree::bulk_load n=1000`
- `bench: RTree::query_rect_intersection n=1000 small query`
- `bench: RTree::query_rect_intersection n=1000 large query`
- `bench: RTree::query_nearest n=1000`

Compare to `rstar-benches/benches/benchmarks.rs`:
`bulk load baseline`, `insert sequential`, `Bulk load complex geo-types
geom`, `bulk load quality`, `locate_at_point (successful/unsuccessful)`,
`locate_at_point_int (successful/unsuccessful)`. The port covers the
bulk-load, dynamic insert/remove, locate, nearest-neighbour, iter, and
drain subset; it omits the generic point/params/iterator-specialisation
surface listed in §4.1/§4.2.

---
