# Milestone: Containment — Contains/Within/Covers

- **Milestone ID:** ms-08-containment
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

ジオメトリ間の包含関係 (`Contains` / `Within` / `Covers`) を MoonBit に移植する。OGC SFA 仕様に基づく境界 / 内部の厳密扱いを `CoordinatePosition` の上に構築する。

## 到達点 (定性)

- `src/geo/2d/contains.mbt` に各組み合わせの `contains(a, b) -> Bool` 相当が実装される (Polygon contains Point, Polygon contains Line, Polygon contains LineString 等)
- `src/geo/2d/within.mbt` に `within(a, b) -> Bool` 相当 (`a` が `b` に含まれる) が実装される (`contains` の逆向き)
- `src/geo/2d/covers.mbt` に `covers(a, b) -> Bool` 相当が実装される (境界点を含む弱包含)
- Rust 版 `contains/`, `within.rs`, `covers/` のテストが完全移植され PASS
- `vp check && test` PASS

## スコープ

- `src/geo/2d/contains.mbt` (または `contains/` ディレクトリ) + `_test.mbt`
- `src/geo/2d/within.mbt` + `_test.mbt`
- `src/geo/2d/covers.mbt` + `_test.mbt`

## 非スコープ

- `ContainsProperly` (内部のみで含む) — Rust 版でも別 trait。本 port では将来検討
- DE-9IM `Relate` ベースの統合判定 — ロードマップ非スコープ

## 依存マイルストーン

- ms-07-topology-basics: `CoordinatePosition` / `Intersects` を内部利用

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/contains/` (各ペアごとに別ファイル), `~/proj/geo/georust-geo/geo/src/algorithm/within.rs`, `~/proj/geo/georust-geo/geo/src/algorithm/covers/`
- 既存 `mbt/package/geo/src/turf/boolean_point_in_polygon.mbt` および `src/util/point_in_ring/` は良いリファレンス (流用ではなく実装方針の確認に留める)
