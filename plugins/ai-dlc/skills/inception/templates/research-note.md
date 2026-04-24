# Research Note: {{topic}}

- **Identifier:** {{identifier}}
- **Topic:** {{topic}}  <!-- existing-impl | dependencies | similar-cases | external-spec | etc. -->
- **Researcher:** {{researcher_instance_id}}
- **Created at:** {{created_at}}
- **Scope:** {{scope}}

## 調査対象

{{target}}

この Research Note が扱う範囲を明示する。Intent Spec のどの制約・どの未解決事項に対応するかを示す。

## 発見事項

{{findings}}

調査で判明したファクト。箇条書きで簡潔に。

- {{finding_1}}
- {{finding_2}}
- {{finding_3}}

## 引用元

{{sources}}

- コードへの参照（`path/to/file.ts:L42` 形式）
- ドキュメントへの参照
- 外部仕様へのリンク
- 関連 ADR

## 設計への含意

{{design_implications}}

発見事項が Design ステップの判断にどう影響するかを明示する。ここが Research Note の価値の中核。

- {{implication_1}}
- {{implication_2}}

## 残存する不明点

{{remaining_questions}}

調査の結果、依然として不明な点があれば Blocker 候補として記録する。追加 Researcher を起動するか、Design で仮定を置いて進めるかを Main が判断する材料となる。
