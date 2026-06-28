# Milestone: Output Plugin Platform

- **Milestone ID:** ms-07-output-plugin-platform
- **Roadmap ID:** feed-platform
- **Status:** planned
- **Created at:** 2026-05-04T00:00:00Z
- **Last updated:** 2026-05-04T00:00:00Z

## 目的

`ms-05` で確定した**出力プラグイン契約スケルトン**に従い、独立サーバレス関数 (= マイクロサービス境界) として展開される出力プラグイン基盤と、最低 1 つの参照アダプタ (Web UI 推奨) を成立させる。新たな出力先を**コードレベルで後付け可能**な構造を確立する。

## 到達点 (定性)

- 出力プラグイン契約 (interface) に従う参照アダプタが少なくとも 1 つ動作し、Event Source of Truth → 出力 Queue → ビュー更新 → キャッシュ DB → Query API → 参照アダプタ (Web UI 推奨) まで end-to-end で通る
- 参照アダプタが**独立サーバレス関数**として実装され、他プラグインと独立にデプロイ・スケール可能な構造であることが design.md 上で示されている
- 「新たな出力アダプタを追加する手順」が文書化され、実際に追加コードのみで拡張できることが構造的に確認できる
- Read-Your-Write 整合戦略 (Tier 1 / Tier 2 / Tier 3) のうち、Web UI 参照アダプタが採用する Tier が確定し、ADR / design.md に記載されている
- 出力プラグイン基盤のテストケース (契約準拠 / 参照アダプタ動作 / Read-Your-Write シナリオ) が網羅され `vp test` で green を維持
- 認証認可基盤と統合され、ユーザー / Organization スコープに応じた出力配信が実現されている

## スコープ

- 対象モジュール: 採用ワークスペース上の出力プラグイン基盤パッケージ、参照アダプタ (Web UI 推奨、ただし配下 oh-my-codingagent execution サイクル Step 1 で最終確定)
- 対象機能: 出力プラグイン契約準拠の参照アダプタ実装、Query API 経由の読み出し、Tier 1 / Tier 2 適用ルールに従う UI ロジック
- 対象 ADR: Web UI 参照アダプタの Read-Your-Write Tier 確定、参照アダプタ選定理由

## 非スコープ

- 永続化基盤 (Event Source of Truth / Projection / CQRS) — `ms-05` の責務
- 出力プラグイン契約 (interface) のスケルトン定義 — `ms-05` の責務
- 入力プラグイン基盤 — `ms-06` の責務
- AI 要約機能 — `ms-09` の責務 (出力プラグインを利用する側)
- API / Slack 等の追加参照アダプタ実装 (本マイルストーンでは 1 アダプタを参照実装として完成させる)

## 依存マイルストーン

- `ms-03-auth-rbac-organization`: 出力配信は認証済みユーザーの Organization スコープに紐付くため、認証認可基盤が前提
- `ms-05-persistence-event-store`: 出力プラグイン契約スケルトンと Query API が前提

## 関連 oh-my-codingagent execution サイクル (workflow_identifiers)

| サイクル `<identifier>` | 状態 | コメント |
| ----------------------- | ---- | -------- |
| (未起動)                | -    | -        |

## 想定 oh-my-codingagent execution サイクル数

1 (推奨)

`ms-05` で契約スケルトンと Read-Your-Write 戦略が先行確定しているため、本マイルストーンは「契約準拠 + 1 つの参照アダプタ実装 + Tier 適用」に集約され、単一サイクルで完遂可能。

## 補足 / 留意事項

- 参照アダプタの第一候補は Web UI (Intent ユーザー要望に直結 / Read-Your-Write 戦略の動作確認に適する)。API / Slack は後続検討
- Web UI 参照アダプタは Tier 1 (純粋な楽観的更新) を default、複数フィールド連動 mutation のみ Tier 2 (Aggregate 断面返却) を採用する形が `design-hint.md` 推奨
- Slack 等の通知系出力は出力 Queue を購読する独立系統 (`design-hint.md` 図中の `NT`) として将来追加予定だが、本マイルストーンの参照アダプタが Web UI である場合は対象外
- `ms-04-auth-shared-access` で導入される共有判定 API を、Web UI が「共有受信者向けビュー」として活用する設計余地を残しておく (本マイルストーンの直接スコープではないが、契約として整合させる)
