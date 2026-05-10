# Milestone: Buffer (Offset) — i_overlay mesh layer

- **Milestone ID:** ms-24-buffer-offset
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

`i_overlay/mesh` 層 (stroke / offset / outline) を MoonBit に port し、polygon / line の buffer (offset) 計算を提供する。upstream Rust `geo` の `buffer` モジュール相当。

## 到達点 (定性)

- `src/i_overlay/mesh/outline/` 相当の outline / offset が動作する (~1,263 LOC)
- `src/i_overlay/mesh/stroke/` 相当の stroke / offset が動作する (~614 LOC)
- `src/geo/2d/buffer.mbt` 相当の公開 API が利用可能:
  - `buffer(geometry, distance) -> MultiPolygon` (positive / negative distance)
  - `buffer_with_options(geometry, distance, options) -> MultiPolygon`
- `BufferOptions` (`join_style: Miter | Round | Bevel`, `end_cap: Butt | Round | Square`, `miter_limit`, `arc_segments`) が定義される
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/i_overlay/mesh/` 全体 (~3,732 LOC 相当)
- `src/geo/2d/buffer.mbt`
- `src/geo/2d/buffer_test.mbt.md`
- `mbt/package/geo-mbt/api-correspondence.md` の `buffer` 行を ⛔ → ✅

## 非スコープ

- 並列 buffer
- buffer 結果の post-processing (simplify 等は配下サイクルで simplify を呼ぶ形に)

## 依存マイルストーン

- ms-23-ioverlay-public-api (mesh は overlay graph に依存)

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

2 サイクル (outline × 1 + stroke × 1)

## Notes

- 移植元:
  - `~/proj/geo/i_overlay/iOverlay/src/mesh/`
  - `~/proj/geo/georust-geo/geo/src/algorithm/buffer.rs` (もしあれば — upstream geo の buffer module を要確認)
