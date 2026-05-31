# Milestone: Auth — Passkey + Magic Link 認証

- **Milestone ID:** ms-02-auth-passkey-magiclink
- **Roadmap ID:** feed-platform
- **Status:** completed
- **Created at:** 2026-05-04T00:00:00Z
- **Last updated:** 2026-05-04T00:00:00Z

このドキュメントは `roadmap` の **Step 2 (Milestone Decomposition)** で `roadmap-planner` Specialist が起草する**1 マイルストーンの定義書**。

## 目的

ユーザーが Passkey および Magic Link で認証可能な認証基盤を構築し、後続のすべての機能領域マイルストーン (永続化を除く) が「認証済みユーザー」前提で実装できる土台を成立させる。

## 到達点 (定性)

- ユーザーが Passkey でサインアップ・ログインできる (実際の Web UI 上で動作確認可能)
- ユーザーが Magic Link でサインアップ・ログインできる (発行されたリンクを踏むとセッションが確立する)
- セッション管理 (発行 / 検証 / 失効) が実装され、後続マイルストーンが「現在のユーザー識別子」を取得できる API 表面が用意されている
- 認証フローのテストケース (正常系・異常系) が成立し、`vp test` で green を維持している
- 認証関連の横断 ADR (Passkey 実装方針 / Magic Link トークン形式 / セッション保持戦略) が `docs/adr/` 配下に確定している

## スコープ

- 対象モジュール: 採用ワークスペース上の認証基盤パッケージ (例: `js/app/feed-platform/auth/` 相当)
- 対象機能: Passkey の登録 / 認証フロー、Magic Link の発行 / 検証フロー、セッション発行 / 検証 / 失効
- 対象ユーザー: 個人開発スコープの単独ユーザー、ただしマルチユーザー前提のスキーマで設計 (RBAC / Organization マイルストーンに引き継ぐため)
- 対象 ADR: Passkey ライブラリ選定、Magic Link 配信経路、セッション保持戦略 (Cookie / JWT / DB セッション 等)

## 非スコープ

- RBAC (3 ロール固定) の実装 — `ms-03-auth-rbac-organization` の責務
- Organization (個人 / 汎用) の概念導入 — `ms-03-auth-rbac-organization` の責務
- 期間限定共有 — `ms-04-auth-shared-access` の責務
- OAuth / SAML 等の他認証方式 (Intent 非スコープ)
- 認証情報を要する具体的な業務機能 (フィード取得・配信等) は後続マイルストーンで認証基盤を利用する形で実装

## 依存マイルストーン

- `ms-01-workspace-foundation`: 採用ワークスペース確定とプロジェクト雛形が前提

## 関連 oh-my-codingagent execution サイクル (workflow_identifiers)

| サイクル `<identifier>` | 状態 | コメント |
| ----------------------- | ---- | -------- |
| (未起動)                | -    | -        |

## 想定 oh-my-codingagent execution サイクル数

1 (推奨)

Passkey + Magic Link は同じ「認証フロー基盤」上に並列実装するため単一サイクルで包む。セッション管理も同一サイクル内に含める (認証フロー成立に不可欠なため)。

## 補足 / 留意事項

- 本マイルストーンで導入されるユーザーモデルは、後続 `ms-03-auth-rbac-organization` で Organization / Role 概念を追加できるよう拡張余地を残しておく (User と Organization の関連は ms-03 で確定)
- Passkey 実装は WebAuthn 標準準拠とし、ライブラリ選定は配下 oh-my-codingagent execution サイクル Step 2 (Research) で確定
- Magic Link の配信経路 (メール / 別チャネル) は配下サイクル Step 1 (Intent Clarification) で確定
