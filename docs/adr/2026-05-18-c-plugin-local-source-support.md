# 2026-05-18 — c-plugin Local Source Support

## Context

c-plugin の `skill add` は GitHub リポジトリのみをソースとしてサポートしており、
ローカルファイルシステム上のプラグインディレクトリから直接インストールできない。
すべてのスキルは `.cache` 経由でクローン・リンクされる。

## Decision

`--local <path>` フラグを追加し、GitHub クローンに加えて
**ローカルパスの直接シンボリックリンク**インストールを可能にする。

### Path Classification

| 分類 | 述語 | 使用箇所 |
|------|------|----------|
| Local path (`./...`) | `isLocalPath` | `--local <path>` の入力形式 |
| Home path (`~/...`) | `isHomePath` | lock-file `skillDirs` の入力形式 |
| Parent path (`../...`) | `isParentPath` | 内部解決のみ（CLI 引数としては不許可） |

- パスは入力されたまま保存（解決後の絶対パスは保存しない）
- 末尾 `/` は正規化して除去
- `--local` は `./...` 形式のみ受理。`~/...` や絶対パス、bare relative は拒否

### Lock File Schema

`RepositoryEntry` を discriminated union に拡張：

```ts
GithubRepositoryEntry = { sourceType: 'github', source, commitHash, marketplaceKind, plugins }
LocalRepositoryEntry  = { sourceType: 'local',  source,             marketplaceKind, plugins }
```

- `commitHash` は `github` 側のみ保持

### SourceType Branching

| 操作 | github | local |
|------|--------|-------|
| `sync` | `ensureRepo` → `checkout` → relink | `ensureLocalPath` → relink |
| `update` | `pull` → `revParseHead` → relink | skip git ops, relink only |
| `remove` | `removeRepo` (cache 削除) | cache 削除スキップ |
| `add` | `ensureRepo` → `revParseHead` → install | `ensureLocalPath` → format check → install |

`Git.checkInstalled` は github ソースが存在する場合のみ実行。

### Validation (Strict)

1. `isLocalPath()` — パス形式検証
2. `hasSupportedPluginFormat()` — `.claude-plugin` / `.cursor-plugin` / `.codex-plugin` の存在確認
3. `ensureLocalPath()` — パス解決 + 実在確認

### Implementation

| File | Change |
|------|--------|
| `src/lib/paths.ts` | `isLocalPath`, `isParentPath`, `isHomePath`, `normalizePathSpec`, `resolveLocalPath`, `findAgentsRoot` |
| `src/lib/plugin-format.ts` | `hasSupportedPluginFormat` |
| `src/schema/lock-file.ts` | `RepositoryEntry` → `GithubRepositoryEntry \| LocalRepositoryEntry` |
| `src/service/cache.ts` | `ensureLocalPath` |
| `src/service/sync.ts` | sourceType branching |
| `src/service/update.ts` | sourceType branching |
| `src/cli/skill/add.ts` | `--local <path>` flag + validation |
| `src/cli/skill/remove.ts` | cache delete skip for local |
| `src/cli/skill/update.ts` | `Git.checkInstalled` → service layer |

各変更に TDD テスト付き。既存 GitHub フローは無変更。

## Consequences

- **Positive**: ローカルプラグイン開発のイテレーションが高速化（clone 不要）
- **Positive**: off-GitHub ソース（private / WIP plugins）を直接利用可能
- **Positive**: `git` 未インストール環境でも local-only 運用が可能
- **Neutral**: lock-file サイズがわずかに増加（`sourceType` フィールド追加）
- **Risk**: `./` 解決基準が `.agents/` の親ディレクトリであることの周知が必要
