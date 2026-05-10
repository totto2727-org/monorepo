# Milestone: R*-tree Full Implementation

- **Milestone ID:** ms-18-rtree-expansion
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

現状 `src/rtree/` は Sort-Tile-Recursive bulk-load + 2 つの query (rect intersection / nearest) のみ。upstream `rstar` クレート相当の本格的な R\*-tree (insert / remove / locate\* / nearest_neighbors / drain / iter) を提供する。これは ms-27 (Delaunay 空間検索) と ms-30 (indexed algorithms) の前提。

## 到達点 (定性)

- `RTree::new() -> Self`, `RTree::insert(Self, Entry) -> Self`, `RTree::remove(Self, Entry) -> Self?` が実装される
- `locate_at_point` / `locate_all_at_point` / `locate_within_distance` / `locate_in_envelope` / `locate_in_envelope_intersecting` が実装される
- `nearest_neighbor` / `nearest_neighbor_with_distance_2` / `nearest_neighbors(k)` / `nearest_neighbor_iter` が実装される
- `iter` / `drain` / `size` / `is_empty` が完備
- `RTreeParams` (fanout, reinsertion strategy, choose-subtree strategy) を表現する設定値型が導入される (デフォルト値固定でも可)
- 既存の bulk-load API は backward-compatible で残される
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/rtree/rtree.mbt` 全面拡張
- `src/rtree/strategy.mbt` (新規: 挿入戦略の R\*-tree split)
- `src/rtree/iter.mbt` (新規: iterator 群)
- `src/rtree/rtree_test.mbt.md` 拡張 (各 API 1 doctest 以上)
- `src/rtree/rtree_bench_test.mbt` 拡張 (insert / remove / locate\* / nearest\* の bench)
- `mbt/package/geo-mbt/api-correspondence.md` の `rtree` 節を 🟡 → ✅

## 非スコープ

- Generic point 抽象 (`Point` / `RTreeNum` / `Envelope` トレイト) — 引き続き 2D `Coord` + `Rect` 固定
- 並列挿入 (rstar の `IntoParallelIterator` 系)

## 依存マイルストーン

- ms-15-validation-finalize

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

2 サイクル (R\*-tree 挿入アルゴリズムと iterator/locate 群を別サイクルに分離する想定)

## Notes

- 移植元: `~/proj/geo/rstar/rstar/src/`
- R\*-tree の choose-subtree / reinsertion / split / overlap-minimisation は Beckmann et al. 1990 を参照
- 挿入時の `RTreeNode::Leaf` ↔ `ParentNode` 切替えは MoonBit の enum variant + 再帰で表現する想定
