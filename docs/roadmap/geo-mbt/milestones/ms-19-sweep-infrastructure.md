# Milestone: Sweep Infrastructure (Bentley-Ottmann + monotone)

- **Milestone ID:** ms-19-sweep-infrastructure
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

`relate` (DE-9IM) と `i_overlay` segment intersection の前提となる sweep-line インフラを整備する。Bentley-Ottmann の event-driven segment intersection と、`monotone` / `monotone_chain` (y-monotone polygon partition) を実装する。

## 到達点 (定性)

- `src/geo/2d/sweep/` モジュールに event queue / sweep status (BST or skip list) が実装される
- `bentley_ottmann_intersections(segments) -> Array[Intersection]` が動作する
- `monotone_partition(polygon) -> Array[Polygon]` が y-monotone な部分多角形列を返す
- `monotone_chain` (Andrew's monotone chain convex hull algorithm) が実装される (現状の Graham scan の代替実装として並走)
- 計算量が O((n+k) log n) (n=入力 segment 数、k=交差数) で動作することを bench で確認
- 全 API が doctest 付きで `vp run --filter @totto2727/geo-mbt test` が PASS する

## スコープ

- `src/geo/2d/sweep/event.mbt`
- `src/geo/2d/sweep/status.mbt`
- `src/geo/2d/sweep/bentley_ottmann.mbt`
- `src/geo/2d/monotone.mbt`
- `src/geo/2d/monotone_chain.mbt`
- 各 `*_test.mbt.md` + 必要な bench
- `mbt/package/geo-mbt/api-correspondence.md` の対応行を ⛔ → ✅

## 非スコープ

- 数値ロバストネス向上 (i_overlay 系の整数座標化は ms-21 で扱う)
- 並列 sweep

## 依存マイルストーン

- ms-15-validation-finalize

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

2 サイクル (Bentley-Ottmann と monotone を別サイクルに分離する想定)

## Notes

- 移植元:
  - `~/proj/geo/georust-geo/geo/src/algorithm/sweep/`
  - `~/proj/geo/georust-geo/geo/src/algorithm/monotone.rs`
  - `~/proj/geo/georust-geo/geo/src/algorithm/monotone_chain.rs`
- sweep status の BST 実装は MoonBit 標準ライブラリの `@immut/sorted_map` を第 1 候補とする (要確認)
