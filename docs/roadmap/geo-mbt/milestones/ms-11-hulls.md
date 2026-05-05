# Milestone: Convex Hull / Concave Hull

- **Milestone ID:** ms-11-hulls
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

凸包 (Convex Hull) と凹包 (Concave Hull) アルゴリズムを MoonBit に移植する。`orient2d` 堅牢述語を内部利用するため `ms-05` 完了後に着手。

## 到達点 (定性)

- `src/geo/2d/convex_hull.mbt` に `convex_hull(geometry) -> Polygon` 相当が実装される (Andrew の monotone chain アルゴリズムまたは Graham scan; Rust 版を踏襲)
- `src/geo/2d/concave_hull.mbt` に `concave_hull(geometry, concavity: Double) -> Polygon` 相当が実装される (k-nearest 凹包、Rust 版 `k_nearest_concave_hull.rs` の実装を踏襲)
- Rust 版テストが完全移植され PASS
- `vp check && test` PASS

## スコープ

- `src/geo/2d/convex_hull.mbt` (または `convex_hull/` ディレクトリ) + `_test.mbt`
- `src/geo/2d/concave_hull.mbt` + `_test.mbt`

## 非スコープ

- 単調分割 (Monotone) / 単調連鎖 (MonotoneChain) — ロードマップ非スコープ
- `MinimumRotatedRect` (回転外接矩形) — ロードマップ非スコープ

## 依存マイルストーン

- ms-05-robust-kernels: `orient2d` を凸包で利用

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/convex_hull/` (mod.rs, graham.rs, qhull.rs 等), `~/proj/geo/georust-geo/geo/src/algorithm/{concave_hull,k_nearest_concave_hull}.rs`
- Rust 版は複数の凸包アルゴリズムを提供しているが、本 port では 1 種類 (Graham scan or monotone chain) のみで開始。Step 3 (Design) で選定
