# ms-18 R-tree Gap Analysis: Bulk-Load Index → Full R\*-tree

**Date**: 2026-05-10  
**Milestone**: ms-18 — "R\*-tree Full Implementation"  
**Status**: planned, depends on ms-15-validation-finalize  
**Phase**: 2 (post-scope expansion)

---

## 1. Current R-tree State (`src/rtree/`)

### Files

| File                              | Purpose                |
| --------------------------------- | ---------------------- |
| `rtree.mbt` (363 lines)           | Core implementation    |
| `rtree.mbt.md` (189 lines)        | Literate documentation |
| `rtree_test.mbt` (111 lines)      | 6 test cases           |
| `rtree_bench_test.mbt` (41 lines) | 4 benchmarks           |
| `moon.pkg` (8 lines)              | Package manifest       |
| `pkg.generated.mbti` (34 lines)   | Generated interface    |

### API Surface (from `pkg.generated.mbti`)

**Types**:
| MoonBit | Visibility | Description |
|---|---|---|
| `pub(all) struct Entry[T] { bbox: Rect, value: T }` | public | Entry wrapping a bbox + payload |
| `type Node[T]` | opaque (package-private) | Leaf(bbox, Array[Entry]) \| Internal(bbox, Array[Node]) |
| `pub struct RTree[T] { root: Node[T]?, size: Int }` | public | The tree itself, root is optional (empty tree) |

**Functions/Methods**:
| MoonBit | Description |
|---|---|
| `pub fn[T] Entry::Entry(Rect, T) -> Entry[T]` | Constructor |
| `pub fn[T] RTree::bulk_load(Array[Entry[T]]) -> RTree[T]` | STR-packed bulk construction |
| `pub fn[T] RTree::is_empty(RTree[T]) -> Bool` | Emptiness check |
| `pub fn[T] RTree::size(RTree[T]) -> Int` | Element count |
| `pub fn[T] RTree::query_rect_intersection(RTree[T], Rect) -> Array[T]` | Intersection query → eager Array |
| `pub fn[T] RTree::query_nearest(RTree[T], Coord) -> T?` | Nearest-by-bbox query |

**Constants**:
| Name | Value | Notes |
|---|---|---|
| `MAX_ENTRIES` | 16 | Hard-coded fanout, no tunable Params |

### Dependencies (`moon.pkg`)

Importing only two packages:

- `totto2727/geo-mbt/geo/2d/type` — for `Rect` and `Coord` types
- `moonbitlang/core/double` — for Double math (`infinity`, `sqrt`, etc.)
- `moonbitlang/core/bench` — test-only, for benchmark harness

No dependency on any external spatial library or heap/priority-queue structures.

---

## 2. rstar Reference API (`~/proj/geo/rstar/rstar/`)

### Directory Structure

```
rstar/src/
├── lib.rs              — Re-exports: RTree, RTreeObject, PointDistance, Envelope,
│                         AABB, Point, ParentNode, RTreeNode, RTreeNum, RTreeParams,
│                         DefaultParams, InsertionStrategy, RStarInsertionStrategy,
│                         SelectionFunction, plus re-xport of algorithm::iterators
├── rtree.rs            — RTree<T, Params> struct + ~46 public methods
├── params.rs           — RTreeParams trait, DefaultParams, InsertionStrategy
├── object.rs           — RTreeObject trait, PointDistance trait
├── envelope.rs         — Envelope trait (new_empty, merge, intersects, area, distance_2, etc.)
├── aabb.rs             — AABB<P: Point>, implements Envelope
├── point.rs            — Point trait, RTreeNum, PointExt (utility methods)
├── node.rs             — RTreeNode<T> enum (Leaf | Parent), ParentNode<T> struct
├── primitives/
│   ├── mod.rs          — Re-exports: CachedEnvelope, GeomWithData, Line, ObjectRef...
│   ├── cached_envelope.rs
│   ├── geom_with_data.rs
│   ├── line.rs
│   ├── object_ref.rs
│   ├── point_with_data.rs
│   └── rectangle.rs
├── algorithm/
│   ├── mod.rs          — Submodule declarations
│   ├── rstar.rs        — RStarInsertionStrategy: recursive_insert, split, reinsert
│   ├── bulk_load/
│   │   ├── mod.rs
│   │   ├── bulk_load_sequential.rs
│   │   └── cluster_group_iterator.rs
│   ├── iterators.rs    — SelectionIterator, SelectionIteratorMut, type aliases for
│   │                     LocateAllAtPoint, LocateInEnvelope, LocateInEnvelopeIntersecting,
│   │                     LocateWithinDistanceIterator, RTreeIterator, RTreeIteratorMut
│   ├── selection_functions.rs — SelectionFunction trait + 7 implementors:
│   │                     SelectInEnvelopeFunction, SelectInEnvelopeFuncIntersecting,
│   │                     SelectAllFunc, SelectAtPointFunction, SelectEqualsFunction,
│   │                     SelectWithinDistanceFunction, SelectByAddressFunction
│   ├── nearest_neighbor.rs — NearestNeighborIterator, NearestNeighborDistance2Iterator,
│   │                     nearest_neighbor_with_distance_2, nearest_neighbors_with_distance_2
│   ├── removal.rs      — DrainIterator, IntoIter
│   └── intersection_iterator.rs — IntersectionIterator (cross-tree intersection candidates)
└── test_utilities.rs   — Test helpers
```

### Complete Public API of `RTree<T, Params>`

**Construction** (4 methods):

- `new()` → `RTree<T, DefaultParams>` — empty tree with default params
- `new_with_params()` → `RTree<T, Params>` — empty tree with custom params
- `bulk_load(elements: Vec<T>)` → `RTree<T, DefaultParams>` — OMT bulk load
- `bulk_load_with_params(elements: Vec<T>)` → `RTree<T, Params>` — bulk load with custom params

**Size queries** (1 public):

- `size(&self) -> usize` — element count (also tracked in an internal `size_mut`)

**Insertion** (1 method):

- `insert(&mut self, t: T)` — R\*-tree insert with rebalancing, O(log n)

**Removal** (4 methods):

- `remove(&mut self, t: &T) -> Option<T>` — remove by equality (requires `T: PartialEq`)
- `remove_at_point(&mut self, point) -> Option<T>` — remove element covering a point (requires `T: PointDistance`)
- `remove_with_selection_function(&mut self, F) -> Option<T>` — generic remove via SelectionFunction
- `pop_nearest_neighbor(&mut self, point) -> Option<T>` — remove nearest element to a point

**Contains** (1 method):

- `contains(&self, t: &T) -> bool` — true if equal element exists in tree

**Locate — Envelope** (8 methods):

- `locate_in_envelope(&self, envelope) -> LocateInEnvelope` — elements fully contained in envelope
- `locate_in_envelope_mut(&mut self, envelope) -> LocateInEnvelopeMut`
- `locate_in_envelope_int(&self, envelope, visitor) -> ControlFlow<B>` — internal iteration variant
- `locate_in_envelope_int_mut(&mut self, envelope, visitor) -> ControlFlow<B>`
- `locate_in_envelope_intersecting(&self, envelope) -> LocateInEnvelopeIntersecting` — elements intersecting envelope
- `locate_in_envelope_intersecting_mut(...)`
- `locate_in_envelope_intersecting_int(...)`
- `locate_in_envelope_intersecting_int_mut(...)`

**Locate — Point** (8 methods):

- `locate_at_point(&self, point) -> Option<&T>` — returns one element covering point
- `locate_at_point_mut(&mut self, point) -> Option<&mut T>`
- `locate_at_point_int(&self, point) -> Option<&T>` — internal iteration, short-circuits
- `locate_at_point_int_mut(...)`
- `locate_all_at_point(&self, point) -> LocateAllAtPoint` — all elements covering point
- `locate_all_at_point_mut(...)`
- `locate_all_at_point_int(...)`
- `locate_all_at_point_int_mut(...)`

**Locate — Distance** (1 method):

- `locate_within_distance(&self, point, max_squared_radius) -> LocateWithinDistanceIterator` — elements within distance

**Locate — Generic** (2 methods):

- `locate_with_selection_function(&self, S) -> SelectionIterator` — arbitrary selection
- `locate_with_selection_function_mut(&mut self, S) -> SelectionIteratorMut`

**Nearest neighbor** (8 methods): (all require `T: PointDistance`)

- `nearest_neighbor(&self, point) -> Option<&T>` — single nearest, no distance
- `nearest_neighbor_with_distance_2(&self, point) -> Option<(&T, Distance)>` — nearest + squared distance
- `nearest_neighbors(&self, point) -> Vec<&T>` — all tied at minimum distance
- `nearest_neighbors_with_distance_2(...) -> Option<(Vec<&T>, Distance)>`
- `nearest_neighbor_iter(&self, point) -> NearestNeighborIterator` — sorted k-NN stream
- `nearest_neighbor_iter_with_distance_2(...)` — sorted with distance² tuples
- `nearest_neighbor_iter_with_distance(...)` — (deprecated)
- `pop_nearest_neighbor(&mut self, point) -> Option<T>` — remove-and-return nearest

**Drain** (5 methods):

- `drain(&mut self) -> DrainIterator` — drain all elements
- `drain_in_envelope(&mut self, envelope) -> DrainIterator` — drain fully contained
- `drain_in_envelope_intersecting(&mut self, envelope) -> DrainIterator` — drain intersecting
- `drain_within_distance(&mut self, point, max_radius²) -> DrainIterator` — drain within distance
- `drain_with_selection_function(&mut self, F) -> DrainIterator` — generic drain

**Iteration** (2 methods + 3 IntoIterator impls):

- `iter(&self) -> RTreeIterator` — iterate all elements (immutable ref)
- `iter_mut(&mut self) -> RTreeIteratorMut` — iterate all elements (mutable ref)
- `impl IntoIterator for RTree` → `IntoIter` (owned, consumes tree)
- `impl IntoIterator for &RTree` → `RTreeIterator` (borrowed)
- `impl IntoIterator for &mut RTree` → `RTreeIteratorMut` (mutably borrowed)

**Cross-tree** (1 method):

- `intersection_candidates_with_other_tree(&self, other: &RTree<U>) -> IntersectionIterator`

**Debug / introspection** (1 method):

- `root(&self) -> &ParentNode<T>` — public access to root for manual traversal

**Total: ~46 public methods** (counting immutable/mutable/internal-iteration variants separately).

---

## 3. Gap Analysis: Current Port vs Full R\*-tree

### Legend

| Symbol | Meaning                                            |
| ------ | -------------------------------------------------- |
| ✅     | Present (possibly under a different name)          |
| 🟡     | Partial — present but in simplified form           |
| ❌     | Missing — needs implementation                     |
| ⛔     | Not applicable to 2D-only, no-generic MoonBit port |
| ➕     | Enhancement of an existing partial                 |

### Construction

| rstar operation                 | Port status | Current port equivalent             | Gap notes                                                                                   |
| ------------------------------- | ----------- | ----------------------------------- | ------------------------------------------------------------------------------------------- |
| `new()`                         | ❌          | —                                   | Current tree is read-only; only `bulk_load` exists. Need an empty-tree constructor.         |
| `new_with_params()`             | ⛔          | —                                   | No `Params` type system in MoonBit; keep hard-coded fanout for now.                         |
| `bulk_load(Vec<T>)`             | ✅          | `RTree::bulk_load(Array[Entry[T]])` | Exists as STR-packing. rstar uses OMT (overlap-minimizing top-down). Acceptable difference. |
| `bulk_load_with_params(Vec<T>)` | ⛔          | —                                   | No tunable params needed.                                                                   |

### Size / is_empty

| rstar operation        | Port status | Notes                           |
| ---------------------- | ----------- | ------------------------------- |
| `size(&self) -> usize` | ✅          | `RTree::size(Self) -> Int`      |
| `is_empty` (derived)   | ✅          | `RTree::is_empty(Self) -> Bool` |

### Mutation: Insert

| rstar operation           | Port status | Gap notes                                                                                                                                                                                                                                                                                                                                                         |
| ------------------------- | ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `insert(&mut self, t: T)` | ❌          | **Major gap.** Requires porting the full R\*-tree insertion algorithm: `RStarInsertionStrategy`, `recursive_insert`, node split strategies, reinsert logic from `algorithm/rstar.rs` (349 lines). Also requires restructuring `Node[T]` from a two-variant enum to support dynamic insertion: parent nodes need Vec-like mutable children, not fixed-size arrays. |

### Mutation: Remove

| rstar operation                                | Port status | Gap notes                                                                                                                                                                         |
| ---------------------------------------------- | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `remove(&mut self, t: &T)`                     | ❌          | Requires `T: PartialEq` — MoonBit has built-in equality on all types. Needs porting `algorithm/removal.rs` (397 lines) — DrainIterator core logic, tree condensing after removal. |
| `remove_at_point(&mut self, point)`            | ❌          | Requires `PointDistance` concept (or equivalent: bbox-distance check).                                                                                                            |
| `remove_with_selection_function(&mut self, F)` | ❌          | Requires `SelectionFunction` trait port.                                                                                                                                          |

### Mutation: Drain

| rstar operation                       | Port status | Gap notes                                                                     |
| ------------------------------------- | ----------- | ----------------------------------------------------------------------------- |
| `drain(&mut self)`                    | ❌          | Drain all elements, consuming the tree.                                       |
| `drain_in_envelope(...)`              | ❌          | Drain elements fully contained in envelope.                                   |
| `drain_in_envelope_intersecting(...)` | ❌          | Drain intersecting elements.                                                  |
| `drain_within_distance(...)`          | ❌          | Drain elements within distance.                                               |
| `drain_with_selection_function(...)`  | ❌          | Generic drain. Requires `SelectionFunction` + `DrainIterator` infrastructure. |

### Query: Envelope-based

| rstar operation                        | Port status | Port equivalent                                   | Gap notes                                                                                                                                       |
| -------------------------------------- | ----------- | ------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `locate_in_envelope(...)`              | ❌          | —                                                 | Fully-contained query (different from intersecting).                                                                                            |
| `locate_in_envelope_intersecting(...)` | 🟡          | `query_rect_intersection(Self, Rect) -> Array[T]` | Current port returns eager `Array[T]`, not a lazy iterator. For full R\*-tree features (especially drain), should be changed to iterator-based. |
| All `_mut` variants                    | ⛔          | —                                                 | MoonBit values are immutable; no mutable variants needed.                                                                                       |
| All `_int` variants                    | ⛔          | —                                                 | Internal iteration pattern is Rust-specific; MoonBit uses iterators differently.                                                                |

### Query: Point-based

| rstar operation            | Port status | Gap notes                                                                                |
| -------------------------- | ----------- | ---------------------------------------------------------------------------------------- |
| `locate_at_point(...)`     | ❌          | Requires `contains_point` concept — in 2D MoonBit port, this is `Rect::contains(Coord)`. |
| `locate_all_at_point(...)` | ❌          | All elements whose bbox contains a point.                                                |

### Query: Distance-based

| rstar operation               | Port status | Gap notes                                                |
| ----------------------------- | ----------- | -------------------------------------------------------- |
| `locate_within_distance(...)` | ❌          | Requires squared-distance check against each entry bbox. |

### Nearest neighbor

| rstar operation                         | Port status | Port equivalent                    | Gap notes                                                                                                                                            |
| --------------------------------------- | ----------- | ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `nearest_neighbor(...)`                 | ✅          | `query_nearest(Self, Coord) -> T?` | Current port returns value (not reference). Note: current impl does bbox-distance only, no `PointDistance` trait.                                    |
| `nearest_neighbor_with_distance_2(...)` | ❌          | —                                  | Needs to return `(T, Double)` tuple.                                                                                                                 |
| `nearest_neighbors(...)`                | ❌          | —                                  | All tied-nearest elements. **Mentioned in ms-18 description.**                                                                                       |
| `nearest_neighbor_iter(...)`            | ❌          | —                                  | Sorted k-NN iterator. **Mentioned in ms-18 description.** Uses a binary heap (priority queue). MoonBit has `priority_queue` in its standard library. |

### Iteration

| rstar operation               | Port status | Gap notes                                                                                           |
| ----------------------------- | ----------- | --------------------------------------------------------------------------------------------------- |
| `iter(&self) -> Iterator`     | ❌          | **Mentioned in ms-18 description.** Requires exposing an iteration mechanism over all leaf entries. |
| `iter_mut(...)`               | ⛔          | Immutable port — no mutable iteration.                                                              |
| `impl IntoIterator for RTree` | ❌          | Consuming iteration — returns all elements, destroys tree.                                          |

### Other

| rstar operation                                | Port status | Gap notes                                                                          |
| ---------------------------------------------- | ----------- | ---------------------------------------------------------------------------------- |
| `contains(&self, &T) -> bool`                  | ❌          | Requires `T: PartialEq`. Simple: search by envelope then equality-check.           |
| `intersection_candidates_with_other_tree(...)` | ❌          | Cross-tree intersection. Complex iterator machinery. Deferred; not in ms-18 scope. |
| `root(&self) -> &ParentNode`                   | 🟡          | Current `Node[T]` is opaque (package-private `type`). Could expose for debugging.  |

### Summary matrix

| Category                        | Count | Status                                                                                                                                                                      |
| ------------------------------- | ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ✅ Fully present                | 3     | bulk_load, size, is_empty                                                                                                                                                   |
| 🟡 Partial                      | 2     | query_rect_intersection (eager, no iterator), query_nearest (returns value not ref, no distance)                                                                            |
| ❌ Missing                      | 32+   | insert, remove, drain, locate_in_envelope, locate_at_point, locate_within_distance, nearest_neighbors, nearest_neighbor_iter, iter, into_iter, contains, drain_all_variants |
| ⛔ N/A (mutable/generic/Params) | ~12   | All `_mut`, `_int`, `_with_params`, `_with_selection_function_mut` variants; `intersection_candidates_with_other_tree`                                                      |

---

## 4. Internal Architecture: What Must Change

### 4.1 Current `Node[T]` is Immutable

The current port uses:

```moonbit
enum Node[T] {
  Leaf(@type.Rect, Array[Entry[T]])
  Internal(@type.Rect, Array[Node[T]])
}
```

This is built once during `bulk_load` and never modified. Each node stores `Array[Node[T]]` / `Array[Entry[T]]` — fixed-size after construction.

**To support insert/remove/drain, `Node[T]` must become mutable.** Options:

1. **Use `Array` with push/pop** — MoonBit `Array` supports mutation, so `Internal(@type.Rect, Array[Node[T]])` already works if the array is mutable. But the current code doesn't mutate after construction.

2. **Separate `LeafNode`/`ParentNode` into distinct types** — match rstar's design where `RTreeNode<T>` is `Leaf(T) | Parent(ParentNode<T>)` and `ParentNode` has mutable `children: Vec<RTreeNode<T>>` plus a cached `envelope`.

Key changes needed to the internal node types:

- Parent nodes need mutable child vectors (currently immutable `Array`)
- Nodes need their envelope recomputed after child changes
- The root needs to be able to split and grow

### 4.2 R\*-tree Insertion Algorithm

From `rstar/src/algorithm/rstar.rs` (349 lines), the insertion algorithm:

1. **`choose_subtree`**: Descend from root, selecting the child whose envelope needs the least enlargement to contain the new element. At leaf level, pick the leaf whose enlargement causes the smallest overlap increase.
2. **`resolve_overflow`**: If a node exceeds `MAX_SIZE` after insertion:
   - Try reinserting some elements (controlled by `REINSERTION_COUNT` parameter)
   - If reinsert was already tried at this level, perform a split
3. **Split strategy**: Choose the split axis that minimizes perimeter, then choose the split index that minimizes overlap.
4. **Root split**: If root overflows, create a new root with two children.

This requires a bottom-up stack tracking the insertion path for overflow propagation.

### 4.3 SelectionFunction Infrastructure

rstar's `SelectionFunction<T>` trait is the linchpin of its query architecture:

```rust
pub trait SelectionFunction<T: RTreeObject> {
    fn should_unpack_parent(&self, envelope: &T::Envelope) -> bool;
    fn should_unpack_leaf(&self, leaf: &T) -> bool { true }
}
```

All `locate_*` methods are built on top of `locate_with_selection_function`, which uses a `SelectionIterator` that traverses the tree, pruning parent nodes via `should_unpack_parent` and selecting leaf items via `should_unpack_leaf`.

The 7 concrete implementations:

- `SelectAllFunc` — always true → `iter()`
- `SelectInEnvelopeFunction` — envelope containment → `locate_in_envelope()`
- `SelectInEnvelopeFuncIntersecting` — envelope intersection → `locate_in_envelope_intersecting()`
- `SelectAtPointFunction` — point containment → `locate_at_point()`
- `SelectEqualsFunction` — equality → `remove()` / `contains()`
- `SelectWithinDistanceFunction` — distance threshold → `locate_within_distance()`
- `SelectByAddressFunction` — pointer comparison → `pop_nearest_neighbor()`

In MoonBit, this maps naturally to a **function-based approach** rather than a trait hierarchy, since MoonBit's trait system is lighter-weight. Each locate method can be a free function that takes a predicate closure, or we can define a MoonBit trait `SelectionFunction`.

### 4.4 Nearest Neighbor Iterator

From `rstar/src/algorithm/nearest_neighbor.rs` (414 lines):

- `NearestNeighborIterator` — yields elements in increasing distance order (k-NN stream)
- `NearestNeighborDistance2Iterator` — yields `(element, distance²)` tuples
- Uses a binary heap (min-heap by distance) of `RTreeNodeDistanceWrapper` entries
- Each `next()` call pops the closest node; if leaf, returns it; if parent, pushes children onto heap

MoonBit has `@priority_queue` in its standard library, which provides the needed min-heap.

The current port's `query_nearest` already uses a similar best-first traversal but only returns the first match. Extending it to a k-NN iterator requires adding a persistent priority queue state.

### 4.5 Drain Iterator

From `rstar/src/algorithm/removal.rs` (397 lines):

- `DrainIterator` — stateful iterator that drains selected elements while maintaining tree structure
- Tracks a stack of `(ParentNode, child_index, insertion_path_index)` triples
- On each `next()`: find the next matching leaf, remove it, then condense the tree upward (merge under-full nodes)
- After dropping the iterator, the tree has been modified in-place

### 4.6 IntoIter (consuming iteration)

From `rstar/src/algorithm/removal.rs`:

- Simple stack-based DFS traversal that pops nodes, yields leaves
- Consumes the RTree (takes ownership of root)

---

## 5. Implementation Plan (Recommended Order)

### Phase A: Internal Restructuring (foundation)

1. **Restructure `Node[T]`** to support mutation:
   - `ParentNode[T]` with mutable `Array[RTreeNode[T]]` + cached envelope
   - `RTreeNode[T] = Leaf(T) | Parent(ParentNode[T])` (renamed from current Enum)
   - Separate `Entry[T]` from `RTreeNode` — Entry becomes the public API; RTreeNode is internal

2. **Port `SelectionFunction` concept**:
   - Define a MoonBit trait or function-based equivalent
   - Implement `SelectAllFunc` and `SelectInEnvelopeFuncIntersecting` first (to replace current `intersecting()` and `nearest_recurse()`)

3. **Port `SelectionIterator`** (stack-based tree walker):
   - Immutable variant only (no `_mut` needed)
   - Replaces current `intersecting()` and `nearest_recurse()` functions

### Phase B: Query Expansion

4. **Add `locate_in_envelope()`** — fully-contained query via `SelectInEnvelopeFunction`
5. **Add `locate_at_point()` / `locate_all_at_point()`** — point-containment query
6. **Add `locate_within_distance()`** — distance-threshold query
7. **Convert `query_rect_intersection` → `locate_in_envelope_intersecting`** returning iterator
8. **Add `iter()`** — via `SelectAllFunc`

### Phase C: Nearest Neighbor Expansion

9. **Upgrade `query_nearest` → `nearest_neighbor_with_distance_2`** — return `(T, Double)?`
10. **Add `nearest_neighbors()`** — all tied-nearest
11. **Add `nearest_neighbor_iter()`** — sorted k-NN iterator using `@priority_queue`

### Phase D: Mutation

12. **Port R\*-tree insertion** (`algorithm/rstar.rs`):
    - `choose_subtree` logic
    - Node split (axis + index selection)
    - Overflow resolution (reinsert vs split)
    - Root split handling

13. **Port removal / drain** (`algorithm/removal.rs`):
    - `remove()` / `remove_at_point()`
    - Tree condensing after removal
    - `drain()`, `drain_in_envelope_intersecting()`

14. **Add `contains()`**

### Phase E: Integration

15. **Convert `bulk_load` to coexist with dynamic insertion**:
    - Bulk-load still produces valid nodes for the dynamic structure
    - May need a `bulk_load_with_params` equivalent that builds `ParentNode`s with correct capacities

16. **Add `IntoIter`** (consuming iteration)

17. **Update `moon.pkg` imports**:
    - May need `moonbitlang/core/priority_queue` for nearest-neighbor iterator

18. **Tests and benchmarks**:
    - Insert + remove correctness tests
    - Tree validity (envelope consistency, child count within bounds)
    - k-NN correctness against brute force
    - Drain + iteration tests

---

## 6. Risk Assessment

| Risk                                                                       | Severity | Mitigation                                                                                                                                                                                                                                      |
| -------------------------------------------------------------------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R\*-tree insertion is algorithmically complex (~349 lines of Rust)         | High     | Port incrementally: split logic first, then insertion, then overflow resolution. Write exhaustive property tests.                                                                                                                               |
| MoonBit lacks `Vec` — `Array` has different resize semantics               | Medium   | Pre-allocate arrays at `MAX_SIZE + 1` capacity; use `Array::push` / `Array::pop` for mutation within capacity. May need to split into new arrays on overflow (similar to Vec realloc).                                                          |
| `SelectionFunction` trait port — MoonBit trait ergonomics differ from Rust | Low      | Can use simple function closures instead of traits for the 2D-only case, or define a local trait.                                                                                                                                               |
| Nearest-neighbor iterator requires a binary heap with custom ordering      | Low      | MoonBit's `@priority_queue` library supports custom comparators.                                                                                                                                                                                |
| Drain iterator requires complex state tracking during removal              | Medium   | Port removal.rs incrementally, testing against brute-force. The condensing logic is the trickiest part.                                                                                                                                         |
| No mutable references in MoonBit                                           | Low      | The port already follows an immutable style. For mutation, we use `let mut tree = ...` and pass `tree` by value where needed. The tree struct itself is mutated in-place via `fn RTree::insert(mut self : RTree[T], t : Entry[T]) -> RTree[T]`. |

---

## 7. Scope Boundaries (What NOT to Port)

Per `CLAUDE.md` and the 2D-only constraint:

| rstar feature                                     | Reason to skip                                                   |
| ------------------------------------------------- | ---------------------------------------------------------------- |
| Generic `T: CoordNum` / `RTreeNum`                | Port uses `Double` only                                          |
| N-dimensional `AABB<P: Point>`                    | 2D `Rect` sufficient                                             |
| `mint` integration                                | External crate interop not needed                                |
| `serde` support                                   | Serialization out of scope                                       |
| `primitives::Line`, `primitives::Rectangle`, etc. | Not needed — port uses `Rect` for envelopes and `T` for payloads |
| `CachedEnvelope`, `GeomWithData`                  | `Entry[T]` already carries bbox + value                          |
| `_mut` variants of all methods                    | Immutable port                                                   |
| `_int` (internal iteration) variants              | Rust-specific pattern; MoonBit callers use iterators             |
| `RTreeParams` / `DefaultParams` / tunable fanout  | Hard-coded `MAX_ENTRIES = 16` is sufficient                      |
| `intersection_candidates_with_other_tree`         | Cross-tree intersection — complex, not used by ms-27/ms-30       |

---

## 8. Key Reference Files

### MoonBit port files

- `/Users/totto2727/.warp/worktrees/monorepo/cobalt-ocotillo/mbt/package/geo-mbt/src/rtree/rtree.mbt` — current implementation (363 lines)
- `/Users/totto2727/.warp/worktrees/monorepo/cobalt-ocotillo/mbt/package/geo-mbt/src/rtree/pkg.generated.mbti` — current interface
- `/Users/totto2727/.warp/worktrees/monorepo/cobalt-ocotillo/mbt/package/geo-mbt/src/rtree/moon.pkg` — current dependencies
- `/Users/totto2727/.warp/worktrees/monorepo/cobalt-ocotillo/docs/roadmap/geo-mbt/roadmap-progress.yaml` — milestone definition (lines 163-182)

### rstar reference files

- `/Users/totto2727/proj/geo/rstar/rstar/src/lib.rs` — crate root with re-exports
- `/Users/totto2727/proj/geo/rstar/rstar/src/rtree.rs` — RTree<T,Params> full API (1372 lines)
- `/Users/totto2727/proj/geo/rstar/rstar/src/algorithm/rstar.rs` — R\*-tree insertion (349 lines)
- `/Users/totto2727/proj/geo/rstar/rstar/src/algorithm/removal.rs` — drain/removal/IntoIter (397 lines)
- `/Users/totto2727/proj/geo/rstar/rstar/src/algorithm/iterators.rs` — SelectionIterator (420 lines)
- `/Users/totto2727/proj/geo/rstar/rstar/src/algorithm/selection_functions.rs` — 7 SelectionFunction impls (240 lines)
- `/Users/totto2727/proj/geo/rstar/rstar/src/algorithm/nearest_neighbor.rs` — k-NN iterator (414 lines)
- `/Users/totto2727/proj/geo/rstar/rstar/src/algorithm/intersection_iterator.rs` — cross-tree intersection (156 lines)
- `/Users/totto2727/proj/geo/rstar/rstar/src/node.rs` — ParentNode, RTreeNode (167 lines)
- `/Users/totto2727/proj/geo/rstar/rstar/src/envelope.rs` — Envelope trait (77 lines)
- `/Users/totto2727/proj/geo/rstar/rstar/src/aabb.rs` — AABB implementation (304 lines)
- `/Users/totto2727/proj/geo/rstar/rstar/src/object.rs` — RTreeObject, PointDistance traits (295 lines)
- `/Users/totto2727/proj/geo/rstar/rstar/src/params.rs` — RTreeParams, DefaultParams (113 lines)
- `/Users/totto2727/proj/geo/rstar/rstar/src/point.rs` — Point trait + tuple/array impls (437 lines)
- `/Users/totto2727/proj/geo/rstar/rstar/src/primitives/mod.rs` — primitive types (15 lines)

### Port documentation

- `/Users/totto2727/.warp/worktrees/monorepo/cobalt-ocotillo/mbt/package/geo-mbt/api-correspondence.md` — §4 rstar section (lines 552-611)

---

## 9. Summary

The current port (`src/rtree/`) is a **read-only, bulk-loaded STR R-tree** with exactly 2 query methods (intersection + nearest), 6 files, and 363 lines of core code. It is intentionally minimal and covers only the "load once, query many" use case.

To become a full R\*-tree matching ms-18 requirements, approximately **32+ rstar API methods** must be added across 5 implementation phases:

1. **Internal restructuring** — mutable `Node[T]`, `SelectionFunction` concept, `SelectionIterator`
2. **Query expansion** — `locate_in_envelope`, `locate_at_point`, `locate_within_distance`, `iter`
3. **Nearest neighbor expansion** — `nearest_neighbor_with_distance_2`, `nearest_neighbors`, `nearest_neighbor_iter`
4. **Mutation** — R\*-tree `insert`, `remove`, `drain`, `contains` (the core dynamic tree operations)
5. **Integration** — make bulk-load coexist with dynamic ops, `IntoIter`, tests/benchmarks

The biggest implementation risks are the R\*-tree insertion algorithm (complex split/reinsert logic) and the drain iterator (stateful tree condensing). The nearest-neighbor iterator is a moderate risk since the current port already has a best-first traversal that can be extended to a persistent iterator using MoonBit's `@priority_queue`.

Approximate LOC estimate: ~2000-3000 new MoonBit lines (the reference Rust code across rstar.rs, rstar.rs, removal.rs, iterators.rs, selection_functions.rs, nearest_neighbor.rs totals ~2700 lines).
