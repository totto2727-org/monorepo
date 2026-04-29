# Research Note: Existing Skills in Repository

- **Identifier:** 2026-04-24-ai-dlc-plugin-bootstrap
- **Topic:** existing-skills
- **Researcher:** （リポジトリ内スキル走査）
- **Created at:** 2026-04-24T13:24:00Z
- **Scope:** 既存スキルとの干渉・衝突の可能性、特に `adr` スキルとの役割分担

## 調査対象

AI-DLC プラグインが既存スキルと共存・干渉するかを確認する。特に:

- `adr` スキル: 意思決定記録の粒度・目的が AI-DLC Design Document と衝突するか
- `git-workflow` スキル: AI-DLC のコミット規約と競合するか
- 他スキル (`effect-*`, `deno-cli-tool`, `csv-analysis` 等) との名前空間衝突

## 発見事項

- **`plugins/totto2727/skills/adr/SKILL.md`** は「雑な意思決定を記録するための軽量ドキュメント」として設計されている（`confirmed: false/true` の承認フロー、短いフォーマット）
- `adr` スキルは個別の意思決定（プロジェクト全体規範、技術選定等）を 1 ファイル = 1 決定で記録する想定
- 体系的な設計ドキュメント（1 サイクル全体のアーキテクチャ・API・コンポーネント図を含む）は既存 `adr` スキルではカバーされていない
- **`git-workflow` スキル** は Conventional Commits + GPG 署名・ステージング・ブランチ運用を定義。AI-DLC のコミット規約はこれと**整合**（`docs(ai-dlc/...):` 型のメッセージは Conventional Commits 準拠）
- 名前空間衝突なし: `ai-dlc` / `main-*` / `specialist-*` / `shared-artifacts` いずれも既存スキル名と被らない

## 引用元

- `plugins/totto2727/skills/adr/SKILL.md` L2-80（スキル仕様）
- `plugins/totto2727/skills/git-workflow/` （本サイクル直接は読み込んでいないが、全体方針として参照）
- 既存スキル一覧（`plugins/totto2727/skills/` のディレクトリ列挙）

## 設計への含意

- **ADR と Design Document を明確に使い分ける**:
  - Design Document (`design.md`): AI-DLC サイクル固有の設計（体系的・詳細・1 サイクル単位）
  - ADR (`adr` スキル): プロジェクト全体に及ぶ横断的な意思決定のみ（軽量・短文・プロジェクト横断）
  - サイクル内の判断は Design Document 内で完結させる。個別判断を ADR 化しない
- **`git-workflow` スキルはそのまま併用可**: AI-DLC のコミット規約は Conventional Commits 準拠なので既存規約と調和
- **shared-artifacts の references パターン** は既存 `skill-reviewer` スキルを参考にできる

## 残存する不明点

- プロジェクト固有の git-workflow 規約（例えば署名ルールやブランチ戦略）と AI-DLC の「タスク単位コミット」がどう両立するか → ケースバイケースで `git-workflow` を優先
- 複数の AI-DLC サイクルが並行進行する場合の identifier 命名規則（本サイクルでは「日付 + 機能名」を採用、プロジェクト規約があればそれを踏襲）
