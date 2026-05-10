# Milestone: Validation Completion (RingRole + indices)

- **Milestone ID:** ms-17-validation-completion
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-10T00:00:00Z
- **Last updated:** 2026-05-10T00:00:00Z

## 目的

Phase 1 の `is_valid` / `validation_problems` は upstream の `ValidationProblem` を一段階フラットに移植したため、`RingRole` (exterior/interior 区別) や coord/ring index などのエラー詳細が落ちている。Phase 2 ではこれらを完全な形に戻し、診断目的でも使える validation 機能に底上げする。

## 到達点 (定性)

- `ValidationProblem` enum が upstream 互換のフィールド (ring role, ring index, coord index, problem detail) を持つ構造に拡張される
- 自交差・重複点・無効リング・退化三角形等が **位置情報付き** で報告される
- 既存呼び出し側 (`is_valid` / `validation_problems`) は backward-compatible に保たれる (新フィールドは optional / 追加 enum variant で表現)
- Rust 版の `validation` モジュールにある全 unit test が doctest として移植される

## スコープ

- `src/geo/2d/validation.mbt` 全面更新
- `src/geo/2d/validation_test.mbt.md` 拡張
- `mbt/package/geo-mbt/api-correspondence.md` の `validation` 行を 🟡 → ✅ に更新

## 非スコープ

- WKT/GeoJSON 形式での validation report 出力 (別途必要なら独立サイクル)
- パフォーマンス最適化 (sweep 連携は ms-19 以降)

## 依存マイルストーン

- ms-15-validation-finalize

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/validation/`
- `RingRole` は `Exterior` / `Interior(usize)` を持つ enum として upstream に存在
