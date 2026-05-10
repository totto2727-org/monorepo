# Milestone: Validation + API Surface Review + Release Prep

- **Milestone ID:** ms-15-validation-finalize
- **Roadmap ID:** geo-mbt
- **Status:** planned
- **Created at:** 2026-05-05T00:00:00Z
- **Last updated:** 2026-05-05T00:00:00Z

## 目的

ジオメトリの妥当性検証 (`Validation`) を移植し、`geo-mbt` パッケージの公開 API 表面を整理してドキュメント (`README.mbt.md`, `CLAUDE.md`) を最終化する。0.1.0 相当の最初のリリース候補を成立させる。

## 到達点 (定性)

- `src/geo/2d/validation.mbt` に `is_valid(geometry) -> Bool`, `validation_problems(geometry) -> Array[Problem]` 相当が実装される (自交差、無効リング、重複点等の検出)
- `src/geo/2d/moon.pkg.json` および各サブモジュールのエクスポートが整理され、`README.mbt.md` に主要 API のサンプルコードが揃う
- `CLAUDE.md` に最終的な構造・コマンド・依存関係が記載される
- ロードマップ全体の `vp run --filter @totto2727/geo-mbt check` および `vp run --filter @totto2727/geo-mbt test` が PASS する
- 全 14 マイルストーンの実装が `geo-mbt` パッケージとして単一プロジェクトに統合され、Rust 版 `geo` のサブセット (2D / Euclidean / 平面アルゴリズム) として機能する
- `moon info` を実行して `.mbti` インターフェイスファイルが生成され、API 表面の差分が確認可能になっている
- `git log` 上で各マイルストーンの完了コミットが確認できる

## スコープ

- `src/geo/2d/validation.mbt` + `_test.mbt`
- `mbt/package/geo-mbt/README.mbt.md` 最終化
- `mbt/package/geo-mbt/CLAUDE.md` 最終化
- 各 `moon.pkg.json` のエクスポート整理
- 全モジュール横断の API 命名・整合性確認

## 非スコープ

- 0.1.0 タグ付け / リリースノート公開 (本ロードマップ完了後の運用)
- crates.io 相当の公開操作 (本ロードマップ非スコープ)
- ロードマップ非スコープのアルゴリズム (Boolean Ops / 三角形分割 / 球面距離 / Relate 等) は別ロードマップに委ねる

## 依存マイルストーン

- ms-08-containment, ms-09-centroid-extremes, ms-10-affine, ms-11-hulls, ms-12-closest-intersection, ms-13-simplify, ms-14-distance-metrics: 全アルゴリズム系マイルストーンの完了

## 関連 dev-workflow サイクル (workflow_identifiers)

- 起票時: 空 `[]`

## 推定 dev-workflow サイクル数

1 サイクル

## Notes

- 移植元: `~/proj/geo/georust-geo/geo/src/algorithm/validation/`
- Validation の出力データ構造 (`Problem` enum) は Rust 版を踏襲しつつ MoonBit の慣習に合わせて整理
- 本マイルストーンは「最終整合性確認」の意味も持ち、各サブモジュール間の不整合があれば修正コミットを起こす権限を持つ
