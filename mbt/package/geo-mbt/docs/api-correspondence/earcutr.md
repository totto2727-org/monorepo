# 5. `earcutr` ↔ `src/geo/2d/earcut.mbt`

Port surface: `src/geo/2d/earcut.mbt` (Phase 2 ms-26). The earcut algorithm
is a self-contained polygon triangulation routine — the upstream crate
provides exactly one user-facing function plus two test/debug helpers,
which keeps the gap matrix short.

| Rust upstream item                                                                                                                              | MoonBit port                                                                           | Status | Notes                                                                                                                                                     |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pub fn earcut<T: Float>(vertices: &[T], hole_indices: &[usize], dims: usize) -> Result<Vec<usize>, Error>`                                     | `pub fn earcut(Array[Double], Array[Int], Int) -> Array[Int]?`                         | ✅     | Hard-coded `Double` (no generic `Float`); returns `None` on bad input (odd-length vertices, dims != 2, hole index past end) instead of `Result<_, Error>` |
| `pub trait Float : num_traits::float::Float`                                                                                                    | —                                                                                      | ⛔     | Numeric-generic abstraction not needed in the port                                                                                                        |
| `pub enum Error { Unknown }`                                                                                                                    | —                                                                                      | 🟡     | Collapsed into `None` from the port's `Array[Int]?` return                                                                                                |
| `pub mod legacy` — `deviation`, `flatten`                                                                                                       | —                                                                                      | ⏳     | Test/debug helpers (input flattener + per-triangle area-error metric); not ported                                                                         |
| z-order hashing path (`LinkedLists::usehash`, `zorder`, `index_curve`, `sort_linked`, `is_ear_hashed`) — performance fast-path for ≥80 verts    | (skipped — port uses `earcut_linked_unhashed` exclusively)                             | 🟡     | Documented `// TODO ms-26-followup`; correctness is identical, runtime degrades to O(n²) per pass for large rings (well over the 80-vertex threshold)     |
| `linked_list` / `eliminate_holes` / `earcut_linked_unhashed` / `is_ear` / `cure_local_intersections` / `split_earcut` / `filter_points`         | (private functions in `earcut.mbt`)                                                    | ✅     | All core helpers ported behind the single public `earcut` entry                                                                                           |
| `LinkedListNode<T>` / `LinkedLists<T>` / `NodeIterator` / `NodePairIterator` / `Vertices<T>` / `VerticesIndexTriangle` / `FinalTriangleIndices` | `priv struct Node` / `LinkedLists` (opaque, `Array[Node]` with NULL sentinel at idx 0) | ✅     | MoonBit reference-array linked list with sentinel; iterator types collapsed into direct index walks                                                       |

### 5.1 Tests / fixture parity

`earcut.mbt.md` — 9 doctests, of which 3 mirror earcutr fixture cases:

| Test                                  | Fixture | Triangles | Notes                           |
| ------------------------------------- | ------- | --------- | ------------------------------- |
| empty input → `Some([])`              | —       | 0         |                                 |
| single triangle (3 verts, no holes)   | —       | 1         |                                 |
| square (4 verts)                      | —       | 2         |                                 |
| square with square hole (4 + 4 verts) | —       | 8         |                                 |
| `building.json` (L-shape, 15 verts)   | yes     | 13        | Matches upstream triangle count |
| `empty-square.json` (degenerate)      | yes     | 0         | Matches upstream                |
| `eberly-3.json` (6 + 6 verts)         | yes     | 12        | Matches upstream                |
| odd-length vertices → `None`          | —       | (error)   | Bad input rejection             |
| hole index past end → `None`          | —       | (error)   | Bad input rejection             |

The full upstream `tests/fixtures/*.json` set (≈30 fixtures) is not yet
mirrored — current coverage is the 3 smallest-and-most-distinctive
fixtures. Adding the larger fixtures (water, dude, etc.) is mechanical
follow-up work and tracked as `// TODO ms-26-fixtures`.

---
