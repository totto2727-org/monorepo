# Milestone: Geographic Algorithms (Densify + cross_track + chamberlain)

- **Milestone ID:** ms-33-geographic-algorithms
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

ms-32 で土台ができた geographic metric spaces を活用し、geographic 系の補助アルゴリズムを実装する。

## 到達点 (定性)

- `densify_haversine(line_string, max_segment_length) -> LineString` が動作する
- `cross_track_distance(point, line_start, line_end) -> Double` (great circle) が動作する
- `chamberlain_duquette_area(polygon) -> Double` (球面 polygon area) が動作する
- `convert_angle_unit` (radian ↔ degree 変換 helper) が提供される
- `Densify` トレイトが geographic metric space でも impl される
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/geo/2d/densify_haversine.mbt`
- `src/geo/2d/cross_track_distance.mbt`
- `src/geo/2d/chamberlain_duquette_area.mbt`
- `src/geo/2d/convert_angle_unit.mbt`
- 各 `*_test.mbt.md`
- `mbt/package/geo-mbt/api-correspondence.md` の対応行を ⛔ → ✅

## 非スコープ

- PROJ ベースの projection (Phase 2 でも未着手)

## 依存マイルストーン

- ms-32-geographic-distances

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元:
  - `~/proj/geo/georust-geo/geo/src/algorithm/densify_haversine.rs`
  - `~/proj/geo/georust-geo/geo/src/algorithm/cross_track_distance.rs`
  - `~/proj/geo/georust-geo/geo/src/algorithm/chamberlain_duquette_area.rs`
  - `~/proj/geo/georust-geo/geo/src/algorithm/convert_angle_unit.rs`
