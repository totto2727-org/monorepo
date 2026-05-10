# Milestone: Geographic Distance/Length/Bearing (Haversine/Vincenty/etc.)

- **Milestone ID:** ms-32-geographic-distances
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

upstream Rust `geo::algorithm::line_measures` の geographic metric spaces (Haversine / Vincenty / Geodesic / Rhumb) と関連 trait impl を実装する。Phase 1 では明示的に out-of-scope だったが、Phase 2 で取り込む。

**重要 (scope 拡張)**: 本マイルストーン着手時に `mbt/package/geo-mbt/CLAUDE.md` の "Scope" セクション (planar Euclidean only) を更新する必要がある。3D は引き続き out-of-scope。

## 到達点 (定性)

- `Haversine` / `Vincenty` / `Geodesic` / `Rhumb` の metric space が定義される
- 各 metric space で `Bearing` / `Destination` / `Distance` / `Length` / `InterpolatePoint` trait が impl される
- `geographiclib-rs` 相当の WGS84 楕円体パラメータが提供される
- `mbt/package/geo-mbt/CLAUDE.md` の Scope セクションが更新される (geographic in-scope, 3D out-of-scope)
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/geo/2d/line_measures/haversine.mbt`
- `src/geo/2d/line_measures/vincenty.mbt`
- `src/geo/2d/line_measures/geodesic.mbt`
- `src/geo/2d/line_measures/rhumb.mbt`
- 各 `*_test.mbt.md`
- `mbt/package/geo-mbt/CLAUDE.md` の Scope 更新
- `mbt/package/geo-mbt/api-correspondence.md` の対応行を ⛔ → ✅

## 非スコープ

- 3D geographic
- PROJ ベースの projection (ms-? に保留 — Phase 2 でも未着手)
- chamberlain_duquette_area / cross_track_distance / densify_haversine (ms-33 の責務)

## 依存マイルストーン

- ms-15-validation-finalize

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

2 サイクル (Haversine + Rhumb × 1 / Vincenty + Geodesic × 1)

## Notes

- 移植元:
  - `~/proj/geo/georust-geo/geo/src/algorithm/line_measures/`
  - `~/proj/geo/geographiclib-rs/src/`
- Vincenty / Geodesic は楕円体計算が複雑。`geographiclib-rs` の Karney アルゴリズムを参照
