# QA Flow: {{title}}

- **Identifier:** {{identifier}}
- **Author:** {{qa_analyst_instance_id}}
- **Source:** `qa-design.md`
- **Created at:** {{created_at}}
- **Last updated:** {{updated_at}}
- **Status:** {{status}} <!-- draft | approved -->

このドキュメントは `qa-design.md` のテストケースを **Mermaid flowchart で可視化**した網羅性確認用の図集。テストの分岐構造をレビュアーが俯瞰できる形で図示することで、認知負荷を下げる。書き方の詳細は `shared-artifacts/references/qa-flow.md` を参照。

## 概要

{{overview}}

qa-flow.md の構成を 2〜5 行で案内する。

例:

- 認証・認可 / 注文処理 / 通知 の 3 関心領域に分割
- エラーハンドリングは「横断的処理」セクションに集約
- ライブラリ仕様由来の防御的分岐は「実装都合分岐」セクションに別途記載

---

## {{concern_1_title}}

このセクションがカバーする成功基準: {{concern_1_sc_ids}}

```mermaid
flowchart TD
  Start([{{concern_1_start_label}}]) --> Q1{{{concern_1_q1_label}}}
  Q1 -->|true| TC_a[{{concern_1_tc_a}}]
  Q1 -->|false| TC_b[{{concern_1_tc_b}}]
```

---

## {{concern_2_title}}

このセクションがカバーする成功基準: {{concern_2_sc_ids}}

```mermaid
flowchart TD
  Start([{{concern_2_start_label}}]) --> Q1{{{concern_2_q1_label}}}
  Q1 -->|admin| TC_x[{{concern_2_tc_x}}]
  Q1 -->|member| TC_y[{{concern_2_tc_y}}]
  Q1 -->|guest| Skip[skip: {{concern_2_skip_reason}}]
```

<!-- 必要な数だけ concern_3, concern_4, ... を追加 -->

---

## 横断的処理 (任意)

エラーハンドリング、ロギング、リトライ等の横断的関心を別図にまとめる場合のセクション。不要なら削除可。

```mermaid
flowchart TD
  Start([{{cross_start_label}}]) --> Q1{{{cross_q1_label}}}
  Q1 -->|...| TC_z[{{cross_tc_z}}]
```

---

## 実装都合分岐 (任意)

既存セクションの flowchart に組み込めない `TC-IMPL-NNN` をここに集約する。Step 6 で implementer が発見した分岐のうち、独立性が高く既存図に自然に入らないものを追記する。Step 4 時点では空でよい。

```mermaid
flowchart TD
  Start([{{impl_start_label}}]) --> Q1{{{impl_q1_label}}}
  Q1 -->|...| TC_impl[TC-IMPL-001: {{impl_tc_label}}]
```
