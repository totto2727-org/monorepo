# Reference: `qa-design.md` の書き方

## 目的

Intent Spec の成功基準を**観測可能なテストケース集合**へと展開する。各テストケースには「実行主体」「検証スタイル」の 2 軸を独立に付与し、特定のテストフレームワーク (Vitest / Playwright / pytest 等) に依存しない抽象レベルで記述する。Step 6 (Implementation) の `implementer` がこのドキュメントを参照してテストを実装し、Step 7 (Validation) の `validator` がカバレッジを実測する。

## 作成者 / 作成タイミング

- **作成者:** `qa-analyst` Specialist (Step 4 で初期作成)
- **更新者:** `implementer` Specialist (Step 6 で「実装段階で発見されたテスト」を追記)
- **承認:** Step 4 完了時にユーザー承認必須 (Artifact-as-Gate-Review)

## ファイル位置

`docs/dev-workflow/<identifier>/qa-design.md`

## セクション構成

```text
1. # qa-design (タイトル)
2. ## 概要 (intent-spec.md の成功基準を深掘りした観測可能な形)
3. ## 自動 vs 手動の判断方針 (アーキテクチャと design.md からの根拠)
4. ## テストファイル配置ポリシー (カテゴリ別の配置方針、具体パスは task-plan で確定)
5. ## 本質テストケース (TC-NNN: 仕様レベルで表現可能な振る舞いを検証)
6. ## 実装都合テストケース (TC-IMPL-NNN: 具体実装でのみ発生する防御的分岐を検証)
7. ## カバレッジ表 (成功基準 → TC-ID の逆引き、Validation で使用)
```

## 各セクションの書き方

### 1. 概要

Intent Spec の成功基準を**そのまま転記しつつ深掘り**する。「速い」のような定性的な記述は「特定シナリオで p95 < 200ms」のような観測可能な形に書き換える。書き換えた結果は qa-analyst が確定し、Step 4 のユーザー承認ゲートで合意される。

成功基準は ID (例: `SC-1`, `SC-2`) を付与し、後続のテストケース表で参照可能にする。

### 2. 自動 vs 手動の判断方針

`design.md` のアーキテクチャ判断を踏まえ、各テストの「実行主体」(automated / ai-driven / manual) を選定した根拠を 1〜3 段落で記述する。例:

- 「フロントエンド UI の見た目確認は人間の目視判定が信頼性高いため `manual × inspection`」
- 「バックエンド API のレスポンス検証は自動テストランナーで再現可能なため `automated × assertion`」
- 「複雑なユーザーシナリオの再現は AI エージェントによるブラウザ操作で代替可能 `ai-driven × scenario`」

### 3. テストファイル配置ポリシー

**カテゴリ別の配置方針のみ**を記述する。具体的なファイルパスは Step 5 (Task Decomposition) で planner / Step 6 で implementer が決める領域。

例:

- `automated × assertion` のテスト → ソースファイルと co-located (例: `foo.ts` と `foo.test.ts` を同ディレクトリ)
- `automated × scenario` のテスト → `e2e/` 直下
- `manual × inspection` の手順書 → `docs/dev-workflow/<id>/manual-tests/<TC-ID>.md`

### 4. 本質テストケース (TC-NNN)

仕様レベル (intent-spec.md / design.md) で表現可能な振る舞いを検証するケース。**Markdown テーブル**で記述する。

#### 必須列 (6 列)

| 列名                 | 内容                                                            | 値例                                                             |
| -------------------- | --------------------------------------------------------------- | ---------------------------------------------------------------- |
| `ID`                 | テストケース識別子 (3 桁ゼロ埋め)                               | `TC-001`                                                         |
| `対象成功基準`       | intent-spec.md の成功基準 ID または `(なし)`                    | `SC-1` / `(なし)`                                                |
| `期待される振る舞い` | 観察可能な事象として記述 (コードがない時点なので振る舞いベース) | `User がログインフォームに正しい認証情報を送信すると 200 を返す` |
| `実行主体`           | 軸 A: enum                                                      | `automated` / `ai-driven` / `manual`                             |
| `検証スタイル`       | 軸 B: enum                                                      | `assertion` / `scenario` / `observation` / `inspection`          |
| `判定基準`           | 合格条件の具体的記述                                            | `HTTP ステータスが 200 かつ JWT が Set-Cookie で返却される`      |

#### 条件付き必須列 (1 列)

| 列名       | 内容                         | 適用条件                             |
| ---------- | ---------------------------- | ------------------------------------ |
| `必要理由` | なぜこのテストが必要かを記述 | `対象成功基準 = (なし)` の場合に必須 |

「対象成功基準 = (なし)」の典型例:

- 防御的プログラミング (不正引数で例外を投げる)
- 内部不変条件の検証 (キャッシュ整合性)
- リグレッション防止 (過去バグの再発防止)
- セキュリティ要件 (Intent Spec で明示されないが必要)

→ 必要理由が空欄なら **Step 4 レビューで差し戻し**

#### 任意列

- `備考` (△組み合わせ採用理由 / 配置ポリシー逸脱の説明 / その他)
- `配置候補` (テストファイル配置の hint、具体パスは task-plan で確定)
- `担当 implementer` (Step 6 で埋まる、Step 4 では空欄)
- `実装状況` (Step 7 で埋まる: `pending` / `implemented` / `passed` / `failed`)

#### 採番ルール

- Step 4 で qa-analyst が `TC-001` から連番採番
- Step 6 で implementer が「振る舞いの追加パターン」を発見した場合、**`TC-NNN` を継続採番** (本セクションに追記)。例: Step 4 で TC-001〜TC-020 までなら、Step 6 追加は TC-021 から
- 削除した場合も**ID は再利用しない** (混乱回避)

### 5. 実装都合テストケース (TC-IMPL-NNN)

ライブラリ / フレームワーク / OS など、**具体実装でのみ発生する防御的分岐**を検証するケース。

- Step 4 では空 (qa-analyst は本質テストのみ設計、実装都合は予見しない)
- Step 6 で implementer が発見した場合のみ追記
- 列構造は本質テストと同じ (ただし `対象成功基準` は通常 `(なし)`、`必要理由` 必須)
- **採番:** `TC-IMPL-001` から連番。本質テストの番号と独立 (混在しない)

#### 本質テストとの判別基準

| 本質テスト (TC-NNN)                                 | 実装都合テスト (TC-IMPL-NNN)                                   |
| --------------------------------------------------- | -------------------------------------------------------------- |
| 仕様レベル (intent-spec.md / design.md) で表現可能  | 特定ライブラリ / フレームワーク / OS の挙動でのみ発生          |
| 別言語 / 別ライブラリで再実装しても同じテストが必要 | 別言語 / 別ライブラリでは不要 or 別の防御的テストになる        |
| 例: 「未認証ユーザーは 401 を返す」                 | 例: 「使用しているライブラリが `null` を返すケースで例外処理」 |

判断に迷う場合は Blocker として Main に報告 (qa-analyst / implementer 共通)。

### 6. カバレッジ表

成功基準 → TC-ID の逆引き表。Step 7 validator がカバレッジ確認に使用する。

例:

| 成功基準 ID | テストケース ID        | 注記 |
| ----------- | ---------------------- | ---- |
| SC-1        | TC-001, TC-005         |      |
| SC-2        | TC-002, TC-003, TC-008 |      |
| SC-3        | TC-010                 |      |
| ...         | ...                    |      |

- **本質テスト (TC-NNN) のみが対象**。TC-IMPL-NNN は成功基準対応がないため現れない
- 1 成功基準に対応する TC が 0 件なら **Step 4 ロールバック** (テスト設計漏れ)

## 検証手段の 2 軸 enum

### 軸 A: 実行主体 (3 値)

| 値          | 意味                                      | 想定具体ツール (qa-design.md には書かない) |
| ----------- | ----------------------------------------- | ------------------------------------------ |
| `automated` | テストランナー / スクリプトが完全自動実行 | Vitest, Jest, pytest, go test 等           |
| `ai-driven` | AI エージェントが対話的に実行             | Claude のブラウザ操作、AI による CLI 実行  |
| `manual`    | 人間が手動で操作・確認                    | 手順書ベースの目視確認、UAT 等             |

### 軸 B: 検証スタイル (4 値)

| 値            | 意味                                   | 業界対応                                   |
| ------------- | -------------------------------------- | ------------------------------------------ |
| `assertion`   | 期待値と実測値の等価判定               | TDD, Property-based testing, snapshot 等   |
| `scenario`    | 一連の操作フローの結果検証             | BDD, E2E testing, smoke test 等            |
| `observation` | 数値・ログ・メトリクスの観測と閾値判定 | Performance testing, observability test 等 |
| `inspection`  | 主観・定性的な確認                     | Exploratory testing, manual UX testing 等  |

### 組み合わせの妥当性 (12 通り)

| 実行主体 \ 検証スタイル | `assertion`               | `scenario`        | `observation`                 | `inspection`                    |
| ----------------------- | ------------------------- | ----------------- | ----------------------------- | ------------------------------- |
| `automated`             | ✓ 単体テスト等 (最も典型) | ✓ E2E スクリプト  | ✓ メトリクス計測 + 閾値       | ✗ **禁止組み合わせ** (本質矛盾) |
| `ai-driven`             | △ 過剰 (理由必須)         | ✓ AI ブラウザ操作 | ✓ AI ログ解析                 | ✓ AI による UX 評価             |
| `manual`                | △ 非効率 (理由必須)       | ✓ 手動シナリオ    | △ 計測は自動化推奨 (理由必須) | ✓ 目視確認                      |

- **✓**: 推奨組み合わせ
- **△**: 条件付きで採用可、`備考` 列に理由必須
- **✗**: 禁止組み合わせ (`automated × inspection`)。主観判定の自動化が可能なら `observation` (定量化) として扱うべき

### 業界 taxonomy との対応

| 業界カテゴリ              | 本 2 軸での表現                                       |
| ------------------------- | ----------------------------------------------------- |
| Unit test (TDD)           | `automated × assertion`                               |
| Integration test          | `automated × assertion` または `automated × scenario` |
| E2E test (Selenium 等)    | `automated × scenario`                                |
| BDD (Cucumber 等)         | `automated × scenario`                                |
| Performance test          | `automated × observation`                             |
| Security scan (SAST/DAST) | `automated × observation`                             |
| Manual UX test            | `manual × inspection`                                 |
| AI-assisted browser test  | `ai-driven × scenario`                                |
| AI による code review     | `ai-driven × inspection`                              |
| Smoke test                | `automated × scenario` (軽量版)                       |

## 品質基準

| ✅ よい                                                     | ❌ 悪い                                                       |
| ----------------------------------------------------------- | ------------------------------------------------------------- |
| 全成功基準が少なくとも 1 つの TC でカバー                   | カバレッジ表に空行 (成功基準対応 TC 0 件)                     |
| 「対象成功基準 = (なし)」のケースに必要理由が記載されている | 必要理由が空欄                                                |
| 各 TC の判定基準が観測可能 (HTTP 200 / p95 < 200ms など)    | 「正しく動く」のような曖昧表現                                |
| `automated × inspection` の組み合わせがない                 | 禁止組み合わせを採用                                          |
| △ 組み合わせには `備考` で理由が記載                        | △ 採用したのに理由なし                                        |
| TC-NNN と TC-IMPL-NNN が独立採番されている                  | 番号が混在 (例: TC-001 と TC-IMPL-001 を併用しているのに別物) |

## 関連成果物

- **入力:** `intent-spec.md` (成功基準), `design.md` (アーキテクチャ判断 = 自動/手動の根拠)
- **出力先:** `task-plan.md` (任意で TC-ID 紐付け), `code` (Step 6 implementer がテスト実装), `validation-report.md` (Step 7 validator がカバレッジ実測)
- **連携:** `qa-flow.md` (本テーブルの TC-ID を Mermaid flowchart の葉として参照、すべての TC-NNN / TC-IMPL-NNN を図示)
