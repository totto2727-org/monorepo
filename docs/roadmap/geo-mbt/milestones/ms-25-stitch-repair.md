# Milestone: Stitch + Repair Polygon

- **Milestone ID:** ms-25-stitch-repair
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

upstream Rust `geo::algorithm::{stitch, repair_polygon}` 相当を実装する。自交差や反転している polygon を BooleanOps エンジンで cleanup する utility。

## 到達点 (定性)

- `stitch_polygon(polygon) -> MultiPolygon` 相当が動作する (隣接面同士の merge)
- `repair_polygon(polygon) -> MultiPolygon` 相当が動作する (自交差・反転リング・退化エッジの修復)
- 上記 2 関数は ms-23 で組んだ BooleanOps エンジンを内部で利用する
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/geo/2d/stitch.mbt`
- `src/geo/2d/repair_polygon.mbt`
- `src/geo/2d/stitch_test.mbt.md` / `repair_polygon_test.mbt.md`
- `mbt/package/geo-mbt/api-correspondence.md` の対応行を ⛔ → ✅

## 非スコープ

- 並列 repair
- 上流に存在しない repair 戦略の追加

## 依存マイルストーン

- ms-23-ioverlay-public-api

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元:
  - `~/proj/geo/georust-geo/geo/src/algorithm/stitch.rs`
  - `~/proj/geo/georust-geo/geo/src/algorithm/repair_polygon.rs` (要確認)
