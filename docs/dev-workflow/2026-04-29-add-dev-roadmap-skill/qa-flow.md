# QA Flow: dev-roadmap スキル新設による戦略層の整備

- **Identifier:** 2026-04-29-add-dev-roadmap-skill
- **Author:** qa-analyst (single instance, post-rollback re-creation)
- **Source:** `qa-design.md` (32 TC)
- **Created at:** 2026-05-01T20:40:00Z
- **Last updated:** 2026-05-01T20:40:00Z
- **Status:** draft

このドキュメントは `qa-design.md` のテストケースを **Mermaid flowchart で可視化**した網羅性確認用の図集。テストの分岐構造をレビュアーが俯瞰できる形で図示することで、認知負荷を下げる。書き方の詳細は `shared-artifacts/references/qa-flow.md` を参照。

## 概要

本サイクルは Markdown / YAML 成果物のみを生み出すドキュメント生成サイクルであり、**実行可能コードに伴う本質ロジック分岐は存在しない**。よって qa-flow.md は「成果物の存在 / 構造 / 意味」を検査軸として 4 つの関心領域に分割する:

- **新規成果物の存在と構造** (SC-1 / SC-2 / SC-3 / SC-4 系) — `dev-roadmap` 系の skill / specialist / agent / テンプレート / reference の有無確認
- **既存成果物の追記整合性** (SC-5 / SC-6 / SC-7 / SC-8 / SC-9 / SC-10 / SC-13 系) — `shared-artifacts/SKILL.md` / `progress.yaml` 関連 / `dev-workflow/SKILL.md` / `README.md` / `specialist-common/SKILL.md` への追記が漏れなく入っているか
- **ディレクトリ構造と命名規則** (SC-12 / SC-14 系 + TC-033) — Step 6 G0 の `git mv` 完了確認、`docs/roadmap/` 構造、retrospective prefix 命名規則
- **説明性 (manual)** (SC-11) — 仮想マイルストーン分解が読者に一意に伝わるか

design.md 確定 4 (Mermaid 記法) に従い、本ファイルでも `graph LR` (DAG 同型 + 既存 task-plan.md パターンと整合) を採用する。各葉ノードには TC-ID または `skip [理由必須]` を配置する。横断的処理 / 実装都合分岐セクションは本サイクル特性上不要のため省略する。

ノード形状の `<` `>` は Mermaid のラベル内で parse 失敗するため、本ファイル内では使用しない (代わりに `lt` `gt` 等で代替、または日本語表記)。

---

## 新規成果物の存在と構造

このセクションがカバーする成功基準: SC-1, SC-2, SC-3, SC-4

`dev-roadmap` 系の新規ファイル群について、(1) ファイルが物理的に存在するか、(2) 期待された frontmatter / 本文セクションを保持しているか、を順に検査する。

```mermaid
graph LR
    Start([新規成果物検査開始]) --> Q1{dev-roadmap/SKILL.md 存在?}
    Q1 -->|true| TC1[TC-001: ファイル存在]
    Q1 -->|false| Skip1[skip: TC-001 fail で全体 fail、後続検査スキップ]
    TC1 --> TC2[TC-002: frontmatter 4 キー]
    TC2 --> TC3[TC-003: 本文 5 セクション]

    TC3 --> Q2{specialist スキル 3 個存在?}
    Q2 -->|true| TC4[TC-004: analyst+planner 存在]
    Q2 -->|2 個のみ| TC5b[TC-005: retrospective-writer 不在 fail]
    Q2 -->|false| Skip2[skip: TC-004/005 fail で後続スキップ]
    TC4 --> TC5[TC-005: retrospective-writer 存在]
    TC5 --> TC6[TC-006: 各スキル必須セクション 4 種]

    TC6 --> Q3{agents 3 個存在?}
    Q3 -->|true| TC7[TC-007: 3 ファイル存在]
    Q3 -->|false| Skip3[skip: 3 個未満で fail]
    TC7 --> TC8[TC-008: description+参照スキル]

    TC8 --> Q4{templates 4 個 + references 4 個?}
    Q4 -->|true| TC9[TC-009: templates 4 個]
    Q4 -->|false| Skip4[skip: 必要数未満で fail]
    TC9 --> TC10[TC-010: references 4 個]
    TC10 --> TC11[TC-011: 1:1 対応 3 件例外検証]
    TC11 --> End1([新規成果物検査完了])
```

---

## 既存成果物の追記整合性

このセクションがカバーする成功基準: SC-5, SC-6, SC-7, SC-8, SC-9, SC-10, SC-13

既存 6 ファイル (`shared-artifacts/SKILL.md` / `templates/progress.yaml` / `references/progress-yaml.md` / `dev-workflow/SKILL.md` / `README.md` / `specialist-common/SKILL.md`) への追記内容と、独立 reference (`references/roadmap-progress-yaml.md`) の必須セクション存在を順に検査する。

```mermaid
graph LR
    Start([既存追記検査開始]) --> Q1{shared-artifacts/SKILL.md 追記?}
    Q1 -->|true| TC12[TC-012: テーブル 4 行追加]
    Q1 -->|false| Skip1[skip: 追記なしで SC-5 fail]
    TC12 --> TC13[TC-013: 1:1 例外リスト 3 件目+件数文言]

    TC13 --> Q2{progress.yaml 関連 2 ファイル更新?}
    Q2 -->|true| TC14[TC-014: roadmap null フィールド存在]
    Q2 -->|false| Skip2[skip: 更新なしで SC-6 fail]
    TC14 --> TC15[TC-015: YAML parseable+roadmap キー]
    TC15 --> TC16[TC-016: references 3 観点 a/b/c]
    TC16 --> TC17[TC-017: 既存サイクル diff 0]

    TC17 --> Q3{dev-workflow/SKILL.md 追記?}
    Q3 -->|true| TC18[TC-018: 開始時段落追加]
    Q3 -->|false| Skip3[skip: 追記なしで SC-7/SC-8 fail]
    TC18 --> TC19[TC-019: 新規セクション独立トップレベル]
    TC19 --> Q4{セクション 5 観点?}
    Q4 -->|all 5 covered| TC20[TC-020: 5 観点 a-e 言及]
    Q4 -->|some missing| TC20F[TC-020: fail 該当観点欠落]
    TC20 --> TC21[TC-021: grep 件数 ≥ 3]

    TC21 --> Q5{README 1 段落?}
    Q5 -->|true| TC22[TC-022: dev-roadmap 段落]
    Q5 -->|false| Skip5[skip: 追記なしで SC-9 fail]

    TC22 --> Q6{references/roadmap-progress-yaml.md 必須セクション?}
    Q6 -->|true| TC23[TC-023: 必須セクション存在]
    Q6 -->|false| Skip6[skip: SC-10 fail]
    TC23 --> TC24[TC-024: 3 観点 何 / いつ / どう書く]

    TC24 --> Q7{specialist-common 列挙更新?}
    Q7 -->|3 名追加| TC29[TC-029: 列挙 12 名]
    Q7 -->|不足| Skip7[skip: SC-13 fail]
    TC29 --> TC30[TC-030: Do NOT use for 列挙更新]
    TC30 --> End2([既存追記検査完了])
```

---

## ディレクトリ構造と命名規則

このセクションがカバーする成功基準: SC-12, SC-14 (および TC-033 = SC なし)

Step 6 G0 の `git mv` 完了確認、`docs/roadmap/<roadmap-id>/` 構造の SKILL.md / shared-artifacts/SKILL.md への記述、retrospective 集約 + prefix 命名規則の明文化を順に検査する。本サイクル特有の機械的タスク (リネーム) の検証が中心。

```mermaid
graph LR
    Start([ディレクトリ構造検査開始]) --> Q1{git mv 完了?}
    Q1 -->|true 5 サイクル移動済| TC26[TC-026: docs/workflow/ 配下 5 サイクル存在]
    Q1 -->|partial 一部移動失敗| TC26F[TC-026: fail 移動漏れ]
    Q1 -->|未実施| Skip1[skip: G0 未完了で全 SC-12 fail]

    TC26 --> Q2{旧 docs/dev-workflow/ 残存?}
    Q2 -->|空 削除済| TC27[TC-027: 旧パス不存在]
    Q2 -->|残存| TC27F[TC-027: fail 残骸あり]
    TC27 --> TC28[TC-028: 既存サイクル diff 0 リネームのみ]

    TC28 --> Q3{docs/roadmap/roadmap-id/ 構造記述?}
    Q3 -->|3 ファイル全言及| TC31[TC-031: 構造 3 ファイル明記]
    Q3 -->|partial| Skip3[skip: SC-14 fail 構造記述漏れ]

    TC31 --> Q4{retrospective 集約言及?}
    Q4 -->|並列配置+集約パス記述あり| TC32[TC-032: 並列配置説明+retrospective 言及 manual inspection]
    Q4 -->|不足| Skip4[skip: SC-14 fail]

    TC32 --> Q5{prefix 命名規則明記?}
    Q5 -->|roadmap-prefix 明記| TC33[TC-033: prefix 命名規則明記]
    Q5 -->|未明記| TC33F[TC-033: fail 命名規則未明記でリグレッション余地]
    TC33 --> End3([ディレクトリ構造検査完了])
```

---

## 説明性 (manual inspection)

このセクションがカバーする成功基準: SC-11

`dev-roadmap/SKILL.md` および `references/roadmap.md` / `milestone.md` を読んだ第三者が、追加情報なしに任意の仮想ゴールから 3 件以上のマイルストーンを抽出できるか、を `manual × inspection` で検証する。

```mermaid
graph LR
    Start([説明性検査開始]) --> Q1{Validation 担当者が 3 ファイル通読?}
    Q1 -->|完了| Q2{仮想ゴール 1 件 例 OAuth 認証導入 を選定?}
    Q1 -->|不可 ファイル不足| Skip1[skip: 通読不能で SC-11 fail]
    Q2 -->|選定| Q3{追加情報なしに 3 件以上のマイルストーン抽出?}
    Q3 -->|3 件以上 抽出可| Q4{各マイルストーンに定性的到達点+依存関係付与?}
    Q3 -->|2 件以下| TC25F[TC-025: fail 説明性不足]
    Q4 -->|全マイルストーンで完備| TC25[TC-025: 説明性 OK manual inspection]
    Q4 -->|一部欠落| TC25F2[TC-025: fail 到達点/依存関係欠落]
    TC25 --> End4([説明性検査完了])
```

注: TC-025 は `manual × inspection` であり、Validation 担当者の判定は `manual-tests/TC-025.md` 手順書に従って実施する。判定の客観性を担保するため、レビュアー 1 名が同じ手順を踏んで実質的に同等のマイルストーンセット (個数 ≥ 3 / 定性到達点が同種 / 依存方向 DAG 一致) を導出できれば pass、別マイルストーン群が導出されたら原文の説明性に揺らぎがあるとして fail。

---

## 横断的処理 (該当なし)

エラーハンドリング / リトライ / ロギング等の横断的関心は本サイクルの検査対象に含まれない (Markdown / YAML 生成のみ、ランタイム挙動なし)。よって本セクションは省略する。

---

## 実装都合分岐 (Step 4 時点では空)

`TC-IMPL-NNN` は Step 6 で implementer が発見した場合のみ追記される。Step 4 時点 (本ファイル作成時) では空。本サイクルは実行可能コードを伴わず、TC-IMPL-NNN が発生する典型的状況 (ライブラリ仕様で null が返る / OS 依存挙動 等) は理論的に発生しにくいため、Step 6 で発見・追記される TC-IMPL は 0〜数件の範囲を見込む。

```mermaid
graph LR
    Start([実装都合分岐 placeholder]) -->|Step 4 時点 空| Empty[TC-IMPL-NNN 未追加]
    Empty --> Note[Step 6 implementer 追記 待ち]
    Note --> End5([Step 6 で本セクション更新])
```
