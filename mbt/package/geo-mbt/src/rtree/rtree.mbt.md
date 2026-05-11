# `rtree/rtree.mbt` — R-tree spatial index

## Goal

Provide a spatial index over items tagged with bounding rects. Build it in one shot with `bulk_load`, or start empty and update it with `insert` / `remove`. You can ask:

- "Which items intersect this query rect?" — `O(log n + k)` where `k` is the result size.
- "Which item is closest to this point?" — `O(log n)` average.

This is **not** a fully-featured R\*-tree: forced reinsertion, condense-tree rebalancing, tunable params, and best-first nearest-neighbour traversal are intentionally omitted. It still supports the dynamic operations needed by geo-mbt's indexed algorithms.

## API surface

```moonbit nocheck
pub(all) struct Entry[T] {
  bbox  : @type.Rect
  value : T
}
pub fn[T] Entry::Entry(bbox : @type.Rect, value : T) -> Self[T]

pub struct RTree[T] {
  root : Node[T]?       // opaque internal node; not user-facing
  size : Int
}

pub fn[T] RTree::bulk_load(entries : Array[Entry[T]]) -> Self[T]
pub fn[T] RTree::new() -> Self[T]
pub fn[T] RTree::insert(self, entry : Entry[T]) -> Unit
pub fn[T : Eq] RTree::remove(self, entry : Entry[T]) -> T?

pub fn[T] RTree::is_empty(self) -> Bool
pub fn[T] RTree::size(self) -> Int
pub fn[T] RTree::iter(self) -> Iter[T]
pub fn[T] RTree::drain(self) -> Array[T]

pub fn[T] RTree::query_rect_intersection(self, query : @type.Rect) -> Array[T]
pub fn[T] RTree::query_nearest(self, target : @type.Coord) -> T?
pub fn[T] RTree::nearest_neighbors(self, target : @type.Coord, limit : Int?) -> Array[T]
pub fn[T] RTree::locate_at_point(self, point : @type.Coord) -> Array[T]
pub fn[T] RTree::locate_within_distance(self, point : @type.Coord, radius : Double) -> Array[T]
```

The `T` type parameter is whatever you want to associate with each rect — the `Entry` carries the bbox (for spatial queries) and a payload `value` of any type.

## What an R-tree is

An R-tree is a **balanced tree of nested bounding rectangles**. Each leaf node holds a small group of `Entry`s; each internal node holds the bbox-of-bboxes of its children. Querying is "descend any subtree whose bbox intersects the query".

```
                        root (bbox of all)
                       ╱      ╱   ╲      ╲
                      ╱      ╱     ╲      ╲
              [child] [child]  [child] [child]    ← internal nodes,
              ╱  ╲      ...      ...      ...        each spans a region
       [leaf] [leaf]
       ╱  ╲    ╱  ╲
   item item item item                              ← leaf entries
```

Queries traverse **only the subtrees whose bounding rects intersect the query**, pruning huge swaths of the index when the query is small. For random queries on uniformly-distributed data, the expected work is `O(log n + k)` — the height of the tree plus the result size.

## Bulk loading

The port uses **STR (Sort-Tile-Recursive)** bulk loading:

```
1. Sort all entries by their bbox centre x.
2. Slice into vertical "tiles" of fixed width (≈ √(num_entries / leaf_capacity)).
3. Within each slice, sort by bbox centre y.
4. Slice into leaf-sized groups.
5. Each group becomes a leaf node; their parent's bbox is the union.
6. Repeat steps 1–5 on the parent nodes until a single root remains.
```

This produces a **balanced** tree with high spatial locality — entries near each other in space end up in the same leaf, which is what makes queries fast.

Bulk loading is `O(n log n)` due to the sorts.

## Queries

### `query_rect_intersection(query)`

Returns every value whose bbox intersects `query`:

```
def search(node, query):
  if node is leaf:
    for each entry in node:
      if entry.bbox intersects query:
        emit entry.value
  else:
    for each child in node:
      if child.bbox intersects query:
        search(child, query)
```

The recursion prunes any subtree whose bbox doesn't overlap `query`. For tightly-packed data, the great majority of subtrees are pruned at the top levels.

### `query_nearest(target)`

Returns the value whose bbox is closest to `target` (a `Coord`). Uses a **best-first traversal** with a priority queue keyed by bbox-to-coord distance:

```
push (root, distance(root.bbox, target)) onto a min-priority-queue
while queue not empty:
  pop the closest node
  if it's a leaf:
    return its closest entry's value
  else:
    for each child:
      push (child, distance(child.bbox, target))
```

The priority queue ensures we visit subtrees in distance-from-target order. The first leaf entry we touch is guaranteed the global nearest because anything else in any not-yet-visited subtree is at least as far away (distance lower-bounded by its bbox).

## Examples

```moonbit nocheck
// Build an R-tree of 100 random rects

///|
let entries = Array::makei(100, fn(i) {
  let i_d = i.to_double()
  let bbox = @type.Rect::Rect(
    @type.Coord(i_d, i_d),
    @type.Coord(i_d + 1.0, i_d + 1.0),
  )
  @rtree.Entry(bbox, i)
})

///|
let tree = @rtree.RTree::bulk_load(entries)

// Find all entries intersecting a rect at (50, 50) – (60, 60)

///|
let q = @type.Rect::Rect(@type.Coord(50.0, 50.0), @type.Coord(60.0, 60.0))

///|
let hits = tree.query_rect_intersection(q)
//   contains values 50, 51, ..., 60 (the 11 entries whose bbox overlaps the query)

// Find the closest entry to (75, 75)

///|
let nearest = tree.query_nearest(@type.Coord(75.0, 75.0))
//   Some(75) — entry 75's bbox is a 1×1 unit square exactly at (75, 75) – (76, 76)
```

Tests in `rtree/rtree_test.mbt`:

- `empty RTree`
- `single entry intersection`
- `many entries: rectangular query`
- `query_nearest: empty returns None`
- `query_nearest: returns the nearest entry`
- `exhaustive verification: query against all entries` — randomly generates entries and queries, checks the R-tree matches a brute-force scan.

Plus benches in `rtree/bench_test.mbt`:

- `bench: RTree::bulk_load n=1000`
- `bench: RTree::query_rect_intersection n=1000 small query`
- `bench: RTree::query_rect_intersection n=1000 large query`
- `bench: RTree::query_nearest n=1000`

## Trade-offs vs. a more sophisticated R-tree

| Feature                                                               | This port                     | rstar (upstream Rust)         |
| --------------------------------------------------------------------- | ----------------------------- | ----------------------------- |
| Insertion / deletion / mutation                                       | No                            | Yes (with rebalancing)        |
| Bulk-load algorithm                                                   | STR (Sort-Tile-Recursive)     | STR + alternative strategies  |
| Tunable leaf capacity / fanout                                        | No (hard-coded)               | Via `RTreeParams`             |
| Tunable insertion strategy                                            | No                            | `RStarInsertionStrategy` etc. |
| Generic over point type                                               | No (2D `Rect` / `Coord` only) | Yes                           |
| `intersection_candidates_with_other_tree`, `nearest_neighbors` (k-NN) | No                            | Yes                           |
| Lines as primitives                                                   | No (only bbox-tagged values)  | Yes (`primitives::Line` etc.) |

For static workloads with bounding-box-tagged values, the port's subset is sufficient. If your workload involves frequent inserts / deletes or needs k-nearest-neighbor (top-k) queries, you'd need to extend the port (deferred work).

## Performance

- **`bulk_load`**: `O(n log n)` due to the sorts during STR.
- **`query_rect_intersection`**: `O(log n + k)` average for tight queries; degrades to `O(n)` for queries covering most of the data.
- **`query_nearest`**: `O(log n)` average; the priority queue ensures we don't visit unnecessary subtrees.

The benchmarks at `n = 1000` give a sense of real-world performance.

## Caveats

- The R-tree is **read-only** after `bulk_load`. To "update" the tree, rebuild from scratch.
- The internal `Node[T]` type is `type Node[T]` (opaque). You can't traverse it manually.
- Currently only **2D** (uses `Rect` and `Coord` from the geo-types layer). 3D would require extending the type machinery.

## Related

- `geo/2d/type/rect.mbt` — the bounding-box primitive every entry carries.
- The wider port-scope discussion in [`docs/api-correspondence/rstar.md`](../../docs/api-correspondence/rstar.md) — only a small subset of `rstar`'s API is mirrored here.
