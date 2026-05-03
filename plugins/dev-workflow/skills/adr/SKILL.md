---
name: adr
description: >
  [Main / Specialist 共通] dev-workflow / dev-roadmap で**サイクルや単一ロードマップを跨いで影響する意思決定**を Architecture Decision Record (ADR) として恒久記録するためのスキル。
  General mode (`docs/adr/<YYYY-MM-DD-title>.md`) は「複数 roadmap を跨ぐ決定」「独立した複数 dev-workflow サイクルを跨ぐ決定」「プロジェクト全体に及ぶ規範」、Roadmap mode (`docs/roadmap/<roadmap-id>/adr/<YYYY-MM-DD-title>.md`) は「単一 roadmap 配下の複数サイクルが共有する文脈」を担う。
  起動トリガー: "ADR を起票", "横断 ADR", "アーキテクチャ判断を記録", "roadmap 共通の前提を残したい", "サイクルを跨ぐ規範を残したい", "create ADR", "record design decision", "check ADR", "architecture decision", "design rationale".
  Do NOT use for: 単一サイクル内で完結する設計判断 (`design.md` 内に書く)、議事録 / メモ書き、コードコメント、Retrospective (`docs/retrospective/`)、Roadmap Intent そのもの (`roadmap.md`)、Milestone 単位の方針 (`milestones/<id>.md`)、CHANGELOG エントリ。
---

# ADR (Architecture Decision Record) — dev-workflow / dev-roadmap 共通スキル

ユースケースカテゴリ: **Document & Asset Creation**
設計パターン: **Domain Intelligence** (ADR ドメインの書き方・運用ルールを埋め込む)

このスキルは、**個別の dev-workflow サイクルを越えて影響が及ぶ意思決定**を恒久記録として残すためのフォーマットと運用ルールを提供する。`design.md` (サイクル固有の設計判断) や Retrospective (揮発的な振り返り) とは役割を分担し、**サイクル / ロードマップ完了後も参照され続ける長寿命の判断記録**を担う。

## 適用モードと保存場所 (核心ルール)

ADR は**起票元の文脈**に応じて 2 つのモードを使い分ける。判定は起票時に Main がスコープを評価して決定し、ADR 本体に明記する。

| モード | 保存場所 | 起票判定の核 | 主な起票元 |
| ---- | -------- | ------------ | ---------- |
| **General mode** (汎用) | `docs/adr/<YYYY-MM-DD-title>.md` | 「**複数 roadmap / 独立した複数 workflow を跨ぐ**」または「**プロジェクト全体の規範**」となる判断 | dev-workflow Step 3 (横断判断発生時) / dev-roadmap Step 1〜4 / 単発の利用 |
| **Roadmap mode** | `docs/roadmap/<roadmap-id>/adr/<YYYY-MM-DD-title>.md` | 「**単一 roadmap 配下の複数 dev-workflow サイクルが共有**」する文脈・前提・規範 | dev-roadmap Step 1〜4 / 配下の dev-workflow サイクル Step 3 (roadmap 文脈下で起動された場合) |

### モード判定フロー

起票判定の早見表:

```
意思決定がサイクル内で完結するか?
│
├── Yes → ADR 不要 (`design.md` 内に書く / `milestones/<id>.md` 内に書く)
│
└── No (複数サイクル / 複数機能 / 他チームに影響) → ADR 起票
    │
    ├── 影響範囲が単一 roadmap 配下に閉じるか?
    │   │
    │   ├── Yes → **Roadmap mode** (`docs/roadmap/<roadmap-id>/adr/`)
    │   │
    │   └── No (複数 roadmap / roadmap 外 / プロジェクト全体)
    │        → **General mode** (`docs/adr/`)
    │
    └── roadmap 文脈が存在しない (単発 dev-workflow サイクル) で
         他の独立 workflow / プロジェクト全体に影響
        → **General mode** (`docs/adr/`)
```

### モード別の起票対象例

#### General mode (`docs/adr/`)

- 「プロジェクト全体で Effect を採用する」
- 「全サービスで gRPC をデフォルト通信規約にする」
- 「認可レイヤを OpenFGA に統一する」
- 「`oauth-rollout` ロードマップと `notification-platform` ロードマップで共通利用するイベントバスの規約」(複数 roadmap 跨ぎ)
- 「dev-workflow サイクル A (検索基盤刷新) と独立して走った dev-workflow サイクル B (CDN 設定刷新) の両方が依拠するキャッシュ層分離方針」(独立サイクル跨ぎ)
- 「pnpm workspace catalog の運用方針」「monorepo の lint / format ルールの統一」

#### Roadmap mode (`docs/roadmap/<roadmap-id>/adr/`)

- 「`oauth-rollout` 配下の全 dev-workflow サイクルが共通利用する `AuthSession` 型定義」(roadmap 内で複数サイクル跨ぎ)
- 「`payment-modernization` ロードマップ全体で 3D Secure 2 を必須とする方針」(roadmap 共有制約)
- 「`notification-platform` ロードマップ内で配信エラー時はリトライキューに投入する規約」(roadmap 内サイクル間共有)
- 「`feed-platform` で feed の正準スキーマを v2 に固定し、配下の取り込み / 配信 / 検索の各サイクルが共通参照する」

#### ADR 不要 (`design.md` 内 / `milestones/<id>.md` 内に書く)

- 「この機能のキャッシュ戦略を LRU にする」
- 「この API のページネーションは cursor 型」
- 「この画面のバリデーションは zod で書く」
- 「このマイルストーン内のリトライ間隔は exponential backoff」(マイルストーン内完結 → `milestones/<id>.md` 内に書く)

### Roadmap mode と General mode の昇格・降格

- **昇格 (Roadmap → General)**: Roadmap mode で書いた ADR が、別 roadmap や独立 workflow にも影響を波及させると判明した場合は、新規 General mode ADR を起票し、旧 Roadmap mode ADR の本文に「`Superseded by docs/adr/<新 ADR>.md`」と追記して `confirmed: true` のまま保存する (immutability principle のため、ファイル内容は書き換えず prefix 追記のみ)
- **降格は原則不可**: General mode ADR を Roadmap mode に降格させない (適用範囲を狭めると過去参照を破壊する)

---

## ファイル仕様

### ファイル名

すべてのモードで共通:

!`echo "$(date +%Y-%m-%d)-title.md"`

- 日付プレフィックス必須 (`YYYY-MM-DD`)
- title はドメインを表す短い英数ハイフン (kebab-case 推奨)
- 例: `2026-04-26-dev-workflow-rename-and-flatten.md` / `2026-04-29-feed-platform-canonical-schema-v2.md`

### Frontmatter

すべての ADR は以下の YAML frontmatter を持つ:

```yaml
---
confirmed: false
scope: general | roadmap:<roadmap-id>
---
```

| Field       | Type    | Description                                                                                                  |
| ----------- | ------- | ------------------------------------------------------------------------------------------------------------ |
| `confirmed` | boolean | `true`: 確定 (原則不変) / `false`: 提案 (レビュー待ち)                                                       |
| `scope`     | string  | `general` (= `docs/adr/` 配下) または `roadmap:<roadmap-id>` (= `docs/roadmap/<roadmap-id>/adr/` 配下)        |

`scope` フィールドは保存場所と一致する必要があり、grep / プログラム的フィルタリングで両モードを区別するためのインデックスとして機能する。`scope` が `roadmap:<roadmap-id>` の ADR は当該 roadmap 配下の任意の dev-workflow サイクルから参照可能、`scope: general` の ADR はリポジトリ全体から参照可能。

### Body 構造

```markdown
---
confirmed: false
scope: general
---

# ADR: タイトル

## Context

なぜこの判断が必要かの背景。**スコープ範囲** (どの roadmap / どの workflow / どのプロジェクト規範に効くか) を明示する。

## Decision

具体的な設計判断。テーブル設計 / API 設計 / ルート設計 / ライブラリ採否 / 方針宣言などを記述する。判断の根拠となる比較材料 (代替案 2-3 個) も簡潔に並べる。

## Consequences

この判断によって生じる影響範囲。

- 新規追加: 新しいテーブル / モジュール / ルート / 規約等
- 既存影響: 変更が必要となる既存コード / 既存運用
- 制約: 今後この判断を前提にすると守るべき制約

## Related

関連する既存 ADR / `roadmap.md` / `milestones/<id>.md` / `design.md` などへのリンクを箇条書きで列挙 (該当なしは省略可)。
```

---

## 運用ルール

### 1. 起票プロセス

1. ADR の起票判定を行う (上記「モード判定フロー」)。判定が曖昧な場合は In-Progress ユーザー問い合わせ形式で確認 (一時レポート: `$TMPDIR/dev-workflow/adr-scope-decision.md` または `$TMPDIR/dev-roadmap/adr-scope-decision.md`)
2. 保存先ディレクトリの存在確認 (なければ作成):
   - General mode: `docs/adr/`
   - Roadmap mode: `docs/roadmap/<roadmap-id>/adr/`
3. ファイル名 `<YYYY-MM-DD>-<title>.md` を決定 (上記「ファイル名」ルール参照)
4. 上記の Frontmatter + Body 構造に従って記述。`confirmed: false` で起票
5. ユーザーレビューに提出 (起票元の dev-workflow / dev-roadmap ステップのゲート判定に乗せる)
6. 承認後、`confirmed: true` に更新して同コミットで保存

### 2. 不変性の原則 (Immutability Principle)

- `confirmed: true` の ADR は原則として本文を変更しない
- 状況変化により以前の判断を改める場合は **新規 ADR を起票し旧 ADR を Superseded として参照する** (旧 ADR 本文の変更は禁止)
- 旧 ADR の本文末尾に `> Superseded by [新 ADR](パス)` の 1 行追記のみ容認 (`confirmed: true` のまま、scope 変更不可)

### 3. ADR の参照ルール

- 実装着手前に**該当する範囲の既存 ADR**を確認する:
  - 単発 dev-workflow サイクル: `docs/adr/` 全件
  - dev-workflow サイクル (roadmap 配下): `docs/adr/` + `docs/roadmap/<roadmap-id>/adr/` の両方
  - dev-roadmap サイクル: `docs/adr/` + `docs/roadmap/<roadmap-id>/adr/` の両方
- `confirmed: true` の ADR と矛盾する実装 / 設計を行わない
- ADR を踏まえないと矛盾する判断が必要になる場合、**先に新規 ADR (または supersede ADR) を起票してから**実装に進む

### 4. 起票元との連携

- **dev-workflow Step 3 (Design)**: `architect` Specialist が「サイクルを跨ぐ判断」を発見した場合、Main に報告。Main がモード判定し、`architect` (または別途 Main 判断で) が ADR を起票する。`design.md` から該当 ADR にリンク
- **dev-workflow `progress.yaml`**: 起票した ADR のパスを `progress.yaml.artifacts.external_adrs` に記録 (General / Roadmap mode どちらも)
- **dev-roadmap Step 1〜2 (Roadmap Intent / Milestone Decomposition)**: `roadmap-analyst` / `roadmap-planner` が roadmap 共有規範を発見した場合、Main 判断で Roadmap mode ADR を起票。`roadmap.md` / `milestones/<id>.md` から該当 ADR にリンク
- **dev-roadmap Step 4 (Roadmap Retrospective)**: 振り返りで導出された roadmap 共有の知見が長寿命前提なら、`roadmap-retrospective-writer` が Roadmap mode ADR を提案 (Main が起票判断)

### 5. retrospective との役割分担

| | ADR | retrospective.md / roadmap-retrospective.md |
| - | - | - |
| 永続性 | 永続 (`confirmed: true` で不変) | 揮発 (次サイクルが改善案を消化したら削除) |
| 内容 | 判断と帰結 (Decision + Consequences) | 振り返り (良かった点 / 課題 / 次回改善案) |
| スコープ | 複数サイクル / roadmap / プロジェクト全体に効く規範 | 1 サイクル / 1 roadmap の自己評価 |
| 保存場所 | `docs/adr/` または `docs/roadmap/<roadmap-id>/adr/` | `docs/retrospective/` (集約) |

retrospective で導出された改善案のうち**永続記録すべき判断**は、retrospective を消化する際に ADR に切り出す。

---

## ディレクトリレイアウト

```
docs/
├── adr/                                       # General mode (cross-roadmap / cross-workflow / project-wide)
│   ├── <YYYY-MM-DD>-<title>.md
│   └── ...
├── roadmap/
│   └── <roadmap-id>/
│       ├── roadmap.md
│       ├── milestones/<milestone-id>.md
│       ├── roadmap-progress.yaml
│       └── adr/                               # Roadmap mode (within single roadmap, across cycles)
│           ├── <YYYY-MM-DD>-<title>.md
│           └── ...
├── workflow/
│   └── <identifier>/
│       └── ...                                # dev-workflow cycle artifacts (does NOT host ADRs directly)
└── retrospective/
    ├── <identifier>.md                        # dev-workflow retrospective (volatile)
    └── roadmap-<roadmap-id>.md                # dev-roadmap retrospective (volatile, prefix 衝突回避)
```

- `docs/workflow/<identifier>/` 配下には ADR を置かない (サイクル固有の判断は `design.md` 内に書く)
- `docs/roadmap/<roadmap-id>/` 配下に `adr/` サブディレクトリを置くのは Roadmap mode のため。Step 1 / 2 着手時に必要に応じて作成 (起票発生時に都度作成可、空でコミットしない)

---

## このスキルが扱わないこと

- 単一サイクル内で完結する設計判断 → `design.md` 内に書く (`shared-artifacts/references/design.md`)
- マイルストーン内で完結する方針 → `milestones/<id>.md` 内に書く
- 議事録・メモ書き → 該当スキルなし (本リポジトリの慣行に従う)
- Retrospective (揮発レポート) → `docs/retrospective/<identifier>.md` または `docs/retrospective/roadmap-<roadmap-id>.md` (`shared-artifacts/references/retrospective.md` / `roadmap-retrospective.md`)
- Roadmap Intent そのもの → `roadmap.md` (`shared-artifacts/references/roadmap.md`)
- CHANGELOG / リリースノート → 該当スキルなし
- ADR を「設計ドキュメントの代替」として乱発すること (1 サイクル内で 5 個以上書きそうなら粒度が間違っている可能性が高く、`design.md` への統合を検討する)
