# MoonBit向け型付きJSON Lens、Builder、検証

## Status

この文書は、`lens`パッケージについてレビュー済みの設計と実装方針を記録するものです。

主な公開抽象化は`Lens[T]`です。lensは既存の`Json`ドキュメントから型付きの値を読み取り、別の`JsonBuilder`へ型付きの値を書き込みます。builderへの書き込みは送信用JSONを構築するものであり、入力ドキュメントを変更したり永続的に更新したりするものではありません。

このレビューはMoonBit 0.10.4および`moonbitlang/core` 0.10.4を対象とします。

## 決定事項の概要

- 型付きJSONアクセス、builderによる構築、集約検証を提供する。
- lensを、パッケージが所有するJSON Pointerと値デコーダーおよびエンコーダーとしてモデル化する。
- `Lens[T]`を型付き値に、`ObjectLens`を型付きオブジェクト値および子プロパティlensを作成できるパスに使用する。
- パッケージ独自のpointer表現を`@json.JsonPath`から独立させる。
- 1つのlensからは`LensError`を発生させ、集約チェックからは非ジェネリックな`Validation`を返す。
- 欠落プロパティと明示的なJSON`null`を異なる状態として保持する。
- `Lens[T]`、`PresenceLens[T]`、`ObjectLens`に静的な結果型を保持し、検証は成功または蓄積された問題のみを報告する。
- 具体的なlens型を集約検証の境界で消去するため、チェック専用の`LensTrait`トレイトオブジェクトを使用する。
- まずオブジェクトプロパティとプリミティブデコーダーから開始する。
- 数値の解析と変換はMoonBit core APIに委譲し、パッケージ独自の数値パーサーは持たない。
- 可変な`JsonBuilder`を通じて送信用オブジェクトを構築し、`ToJson`を実装する。
- `Lens::set`はbuilderを対象とする書き込みとし、欠落しているオブジェクト親を作成するが、既存のJSONドキュメントは更新しない。
- optionality、配列、refinement、変換、alternativeは基盤が安定してから追加する。
- 不透明なデコーダークロージャからJSON SchemaやOpenAPIを生成できるとは約束しない。
- ソースドキュメントの変更はbuilder APIと検証APIの外部に置く。
- 検証APIに値の構築、型推論、変更操作を追加しない。

## 問題の定義

MoonBitの標準`Json`型はJSON値を表し、`FromJson`トレイトは完全な値をMoonBit型へデコードし、`ToJson`トレイトは完全な値をエンコードします。このパッケージは、1つのJSONドキュメントから既知の場所を繰り返し選択する用途と、各呼び出し側で`Map[String, Json]`を手作業で管理せずに、型付きの場所を再利用して送信用JSONオブジェクトを構築する用途に対応します。

中核モデルは次のとおりです。

```text
ObjectLens
└── object accessor: Lens[Map[String, Json]]

Lens[T]
├── location: Pointer
├── value interpretation: Decoder[T]
└── output encoding: Encoder[T]

JsonBuilder
└── generated object path tree
```

このパッケージは、汎用JSONクエリ言語、完全なHaskell lens実装、`FromJson`や`ToJson`導出の置き換えを意図していません。builderへの書き込みはlensのpointerと型付きエンコーダーを再利用しますが、ソースドキュメントの変更は対象外です。

## 元の提案を変更するレビュー結果

### 共有型付きロケーションとして`Lens`を維持する

従来のlensは読み取りと規則的な更新の両方をサポートします。しかしこのパッケージでは、1つの型付きロケーションを入力デコードと出力構築に再利用します。`Lens::set`は可変な`JsonBuilder`を対象とするため、builder setterであり、ソースドキュメントの更新ではありません。

パッケージと公開型では`lens`と`Lens[T]`を維持し、メソッドシグネチャとドキュメントで対象を明示します。既存のJSONドキュメントは、パッケージの観点では不変のままです。

### pointer表現を所有する

現在の`@json.JsonPath`インターフェースは抽象`JsonPath`型とappendメソッドを公開しますが、公開されたrootコンストラクターはありません。主に`FromJson`と`JsonDecodeError`向けに設計されています。

そのため、パッケージには独自の不透明な`Pointer`型が必要です。内部ではRFC 6901 JSON Pointerとして表示し、安全な構築および検査操作だけを公開します。`@json.JsonPath`に依存すると、パッケージはroot pathを構築できず、公開エラーモデルをcore内部実装に結び付けることになります。

### トラバーサルに失敗した場所を報告する

lookupでは、要求されたpointerと、正常にトラバーサルできたprefixの両方を追跡する必要があります。

`/user/profile/name`を要求した場合:

- `name`が存在しなければ、`/user/profile/name`を報告する。
- `profile`が文字列なら、`/user/profile`で型不一致を報告する。
- `user`が存在しなければ、`/user`を報告する。

すべての失敗で要求された完全なpointerを報告すると、中間値の型エラーを誤った場所として示すことになります。

### 発生するエラーと検証データを分離する

`Lens::get`は`Result`を返すのではなく、パッケージ固有の`LensError`を発生させるべきです。このエラーは1つの`Issue`を保持します。`Issue`は単純な構造化値として保持し、例外をコレクションとして使わずに集約検証で多くの問題を保持できるようにします。

この分離により、各型に1つの役割を持たせられます。

- `LensError`は`raise`と`catch`で使う型付き制御フロー境界である。
- `Issue`はpointer、安定したコード、任意のメッセージを含む検査可能な診断データである。

`CustomError`は公開パッケージAPIとして汎用的すぎます。`LensError(Issue)`は、所有する抽象化と再利用可能な診断ペイロードの両方を示します。

### lensの静的型を維持する

MoonBitは、TypeScriptライブラリがZodスキーマ式から型を推論するように、実行時コレクションに含まれる検証定義からコンパイル時の結果型を導出できません。検証APIは、`Schema[T]`、固定個数builder、値を生成する検証結果によってそのモデルを模倣すべきではありません。

`Lens[T]`はプリミティブ値とraw JSON値の静的型情報の源です。`ObjectLens`は`Lens[Map[String, Json]]`を所有するため、静的に型付けされたオブジェクトアクセスも提供します。集約検証はチェック専用の`LensTrait`トレイトオブジェクトを通じて両方を受け取り、すべてのチェックを評価し、成功または蓄積された問題だけを返します。呼び出し側で明示的な変換を行う必要はありません。検証成功後は、元のlensを通じて値を読み続けます。

この設計では、検証後のアクセスでトラバーサルとデコードが再度行われます。この重複を避けるには、異種型付きキャッシュまたはアプリケーションごとに生成されたコードが必要ですが、どちらも初期パッケージには属しません。

### 数値変換をMoonBit coreに委譲する

パッケージはJSONトラバーサル、型選択、構造化エラーマッピングを所有すべきですが、小数、指数、符号、オーバーフロー、丸めのアルゴリズムを所有すべきではありません。

`Json::Number`ではMoonBit coreがすでに生成した`Double`値を使います。保持された元テキストを再解析してはいけません。`Int`が要求された場合は、`Double::to_int()`に直接委譲し、パッケージレベルの検証なしに標準変換の動作を継承します。

後から数値テキストを受け付けるデコーダーを追加する場合は、`@string.from_str`、`@string.parse_double`、`@string.parse_int`など、現在サポートされている非deprecated標準エントリポイントに解析を委譲し、発生した標準エラーを`DecodeProblem`へ変換します。レビュー対象のツールチェーンでは、`@strconv.parse_*`がdeprecatedな互換APIとして引き続き公開されています。新しいパッケージコードでは、サポートされている`@string`の置き換えを使うべきです。

手書きの数字ループ、数値文法を重複させる正規表現、パッケージ固有の小数または指数パーサーは対象外です。これにより、標準ライブラリの意味と保守を重複させずに済みます。

### optionalityを公開する前に存在意味論を設計する

欠落と`null`は異なります。

| 入力状態 | 必須文字列 | Optional文字列 | Nullable文字列 | Optional nullable文字列 |
| -------- | ---------: | -------------: | -------------: | ----------------------: |
| 欠落     |     エラー |         `None` |         エラー |                  `None` |
| `null`   |   型エラー |       型エラー |         `None` |                  `None` |
| 文字列   |         値 |  `Some(value)` |  `Some(value)` |           `Some(value)` |

presence combinatorを適用すると`PresenceLens[T]`になり、decodeおよびencodeする値の型は`T?`になります。別のpresence combinatorを適用してもoption型はネストせず、後のpolicyが前のpolicyを置き換えます。最後の呼び出しが欠落値とJSON `null`の両方の動作を決定します。

```moonbit
lens.optional()
lens.nullable()
lens.nullish()
lens.optional().nullable() // lens.nullable()と同等
```

特に`optional().nullable()`と`nullish().nullable()`はnullishではなくnullableです。プロパティの欠落はエラーになり、JSON `null`は`None`へdecodeされ、`None`はJSON `null`としてencodeされます。

### 値のalternativeとロケーションfallbackを分離する

`or`操作は曖昧です。次のどちらも意味し得ます。

- 同じ選択済みJSON値に対して別のデコーダーを試す。
- 最初のlensが失敗した場合に別のロケーションを試す。

設計では別の名前を使用する必要があります。

```text
Decoder::one_of2     alternatives for one value
Lens::or_else        fallback to another location, if this feature is needed
```

初期検証ロードマップに属するのは、値のalternativeだけです。

### unknown-field検証にはオブジェクトメタデータが必要

独立した`LensTrait`チェックだけで構成されたvalidatorは、オブジェクトで許可されるプロパティの完全な集合を知りません。そのため、unknown fieldの拒否を初期の集約validatorの単純なオプションとして正しく追加することはできません。

unknown-field検証は、オブジェクト境界と宣言されたキーを記録する明示的なobject-check表現を待つ必要があります。`strip_unknown`と`passthrough`はデータを変換または返すため、検証専用APIには属しません。

### スキーマ生成には宣言的なデコーダーメタデータが必要

不透明なpredicateおよびtransformクロージャをJSON SchemaやOpenAPIへ確実に変換することはできません。pointerとdecoderの分離は実装構造を改善しますが、スキーマ生成には不十分です。

後から宣言的な制約モデルが導入されない限り、スキーマ生成は非目標です。

## アーキテクチャ

### Pointer

`Pointer`はパッケージの不透明型です。内部では順序付きのpath segmentを保持します。

```moonbit
priv enum PointerSegment {
  Key(String)
  Index(Int)
}

pub struct Pointer {
  priv segments : Array[PointerSegment]
}
```

フェーズ1ではキーによるトラバーサルだけを公開します。配列サポートでindexトラバーサルを公開します。

文字列表現はRFC 6901に従います。

- rootは空文字列として表示する。
- キーは`/key`を追加する。
- `~`は`~0`としてエスケープする。
- `/`は`~1`としてエスケープする。
- 配列indexは10進表現を追加する。

### Decoder

`Decoder[T]`は、すでに選択された1つのJSON値を解釈します。ドキュメントのトラバーサルは行いません。

```moonbit
pub struct Decoder[T] {
  priv decode_ : (Json) -> T raise DecodeProblem
}
```

`DecodeProblem`は、pathに依存しない失敗情報を含むパッケージ非公開のサブエラーです。`Lens::get`はこれを捕捉し、選択されたpointerを付加して公開`Issue`を生成し、`LensError(issue)`を発生させます。

プリミティブデコーダーはJSON variant dispatchを直接行い、パッケージが安定した構造化エラーコードを提供できるようにします。デコーダー内の数値解析と変換はMoonBit coreに委譲する必要があります。後の`Decoder::from_json[T : FromJson]` bridgeでは`JsonDecodeError`を捕捉できますが、coreの人間向けメッセージは安定した構造化エラーコードではないため、失敗は外部デコード失敗として分類すべきです。

### Encoder

`Encoder[T]`は、型付き値を1つの具体的なJSON値へ変換します。プリミティブエンコーダーはMoonBit coreのJSONコンストラクターに委譲し、プロパティ省略は`Encoder`ではなく`PresenceLens::set`が担当します。JSON配列は後続indexをずらさずに欠落要素を含められないため、`PresenceLens::array`はすべてのpresence modeをencode/decodeともにnullableな項目意味論へ正規化します。JSON `null`は`None`へデコードされ、`None`はJSON `null`としてエンコードされます。

presence combinatorには明示的なbuilder動作があります。

| Lens                        | `Some(value)`        | `None`                  |
| --------------------------- | -------------------- | ----------------------- |
| `nullable`                  | 値をエンコードする。 | JSON `null`を書き込む。 |
| `optional`                  | 値をエンコードする。 | プロパティを省略する。  |
| `nullish()`                 | 値をエンコードする。 | プロパティを省略する。  |
| `nullish(encode_mode=Null)` | 値をエンコードする。 | JSON `null`を書き込む。 |

`NullishEncodeMode`は、JSON`null`が必要な場合の送信表現を明示し、デフォルトでは省略します。実装では独立したnullish encoderを保持せず、既存のoptionalまたはnullable encoderを選択します。

### JSON builder

`JsonBuilder`は可変な送信用オブジェクトbuilderです。内部ノードは、エンコード済みJSON leafと生成されたオブジェクト親を区別します。`Lens::set`はパッケージ所有のpointerをたどり、欠落しているオブジェクト親を作成し、エンコード済みleafを書き込みます。同じpointerへの再書き込みは値を置き換えます。エンコード済みleafを中間ノードとして使用すると、正確な競合pointerで`JsonBuildError`を発生させます。

`optional(None)`は同じpointerにある以前の値を削除し、空になった生成親をpruneします。`BuildNode`は`ToJson`を実装します。生成オブジェクトノードは`Map[String, BuildNode]::to_json`へ直接委譲し、エンコード済みleafは変更せずに通過させます。各変換は生成オブジェクトノード用に新しいmapを作成するため、後のbuilder書き込みが以前の結果を変更することはありません。

### Object lens

`ObjectLens`は、子プロパティを宣言できる型付きオブジェクトロケーションを表します。内部の`Lens[Map[String, Json]]`へトラバーサルとオブジェクトデコードを委譲します。オブジェクトデコードは選択されたトップレベルmapをコピーするため、返されたmapへの変更がソースドキュメントに影響することはありません。ネストされた`Json`値は標準的な共有意味論を保持します。

```moonbit
pub struct ObjectLens {
  priv lens : Lens[Map[String, Json]]
}
```

`ObjectLens::get`を通じて選択されたオブジェクトを返し、`Lens[String]`から子文字列プロパティを作成するような不正なAPIを防ぎます。

### 型付きlens

```moonbit
pub struct Lens[T] {
  priv pointer : Pointer
  priv decoder : Decoder[T]
  priv encoder : Encoder[T]
}
```

`Lens::get`は2つの操作を行います。

1. lensのpointerまでドキュメントをトラバースする。
2. 選択された値をdecoderでデコードする。

トラバーサルとデコードの失敗は同じ公開`Issue`値へ正規化され、`LensError`として発生します。

`Lens::set`は値をエンコードし、`JsonBuilder`へ書き込みます。エンコードと構築の失敗は`JsonBuildIssue`へ正規化され、`JsonBuildError`として発生します。読み取り側の`LensError`契約は変更しません。

## フェーズ1の公開API

正確な宣言構文は実装時に確認する必要がありますが、意図するAPIの範囲は次のとおりです。

```moonbit
pub fn root() -> ObjectLens

pub fn object(String) -> ObjectLens

pub fn ObjectLens::object(
  Self,
  String,
) -> ObjectLens

pub fn ObjectLens::string(
  Self,
  String,
) -> Lens[String]

pub fn ObjectLens::bool(
  Self,
  String,
) -> Lens[Bool]

pub fn ObjectLens::number(
  Self,
  String,
) -> Lens[Double]

pub fn ObjectLens::int(
  Self,
  String,
) -> Lens[Int]

pub fn ObjectLens::json(
  Self,
  String,
) -> Lens[Json]

pub fn ObjectLens::get(
  Self,
  Json,
) -> Map[String, Json] raise LensError

pub fn Lens::get[T](
  Self[T],
  Json,
) -> T raise LensError

pub(all) enum NullishEncodeMode {
  Omit
  Null
}

pub fn Lens::nullish[T](
  Self[T],
  encode_mode? : NullishEncodeMode,
) -> PresenceLens[T]

pub fn JsonBuilder::JsonBuilder() -> JsonBuilder

pub impl ToJson for JsonBuilder

pub fn Lens::set[T](
  Self[T],
  JsonBuilder,
  T,
) -> Unit raise JsonBuildError
```

`object("user")`は`root().object("user")`の便利な別名です。

例:

```moonbit
fn read_name(document : Json) -> String raise LensError {
  object("user").object("profile").string("name").get(document)
}

let name : String = read_name(document)
```

## Lookupの意味論

Lookupはrootから進み、各segmentが成功するたびにトラバース済みpointerを記録します。

概念的には次のとおりです。

```text
lookup(document, requested_pointer)
  current = document
  traversed = root

  for segment in requested_pointer:
    if segment is a key:
      require current to be an object at traversed
      extend traversed with the key
      require the property to exist at traversed
      current = property value

    if segment is an index:
      require current to be an array at traversed
      extend traversed with the index
      require the index to exist at traversed
      current = array item

  return current
```

フェーズ1ではキーsegmentだけを構築しますが、内部の失敗位置ルールはすでにテストでカバーする必要があります。

## エラーモデル

エラーは構造化データであり、あらかじめ整形された文字列ではありません。

```moonbit
pub(all) enum JsonKind {
  Null
  Boolean
  Number
  String
  Array
  Object
}

pub(all) enum IssueCode {
  MissingProperty
  TypeMismatch(
    expected~ : JsonKind,
    actual~ : JsonKind,
  )
  IndexOutOfBounds(
    index~ : Int,
    length~ : Int,
  )
  ConstraintViolation(
    code~ : String,
  )
  ExternalDecode
}

pub(all) struct Issue {
  pointer : Pointer
  code : IssueCode
  message : String?
}

pub(all) suberror LensError {
  LensError(Issue)
}
```

最終的な公開範囲は狭めても構いませんが、利用者はテキストを解析せずにpointerとcodeを検査できなければなりません。

`message`フィールドは任意の診断コンテキストです。プログラムのロジックは`message`ではなく`IssueCode`に基づいて分岐すべきです。

pointerは欠落プロパティをすでに識別するため、エラーに重複したプロパティ名フィールドは必要ありません。

`Issue`自体はサブエラーではありません。これを`LensError`のペイロードとして保持することで、`Validation::Invalid`は`Array[Issue]`を直接保存でき、`Lens::get`の呼び出し側はMoonBitの型付きエラー伝播を利用できます。

## プリミティブデコードの意味論

### String

`Json::String`だけを受け付けます。

### Boolean

`Json::True`と`Json::False`だけを受け付けます。

### Number

`Json::Number`だけを受け付けます。

フェーズ1の`number` decoderは、`Json::Number`にすでに保存されている`Double`を返します。有限性や範囲の検証は行いません。保持されたテキスト表現を調査または再解析することもありません。

### Integer

JSONには独立した整数型はなく、数値型があります。`int` decoderは、`Json::Number`にすでに保存された`Double`に対して直接`Double::to_int()`を適用します。有限性、範囲、整数としての正確性は検証せず、MoonBitの標準的な切り捨て、飽和、特殊値の動作を継承します。パッケージはJSON数値テキストを解析してはいけません。

### Raw JSON

`json` decoderは選択された値で常に成功します。

## 1つのlensが`LensError`を発生させる理由

MoonBitでは、パッケージ定義のsuberrorに対して型付きの`raise`と`catch`動作が提供されます。`Lens::get`はこのネイティブな制御フローを使い、通常の読み取りで1つの失敗を伝播させながら、呼び出し側に`Result`のunwrapを強制しません。

集約検証は値ベースのままです。`validate`は各チェックごとに`LensError(issue)`を捕捉し、含まれる`Issue`を保持し、収集したすべての問題を`Validation::Invalid`として返します。1つのチェックの失敗が、他の独立したチェックの評価を妨げてはいけません。

## フェーズ2の集約検証

### Validation

```moonbit
pub enum Validation {
  Valid
  Invalid(Array[Issue])
}
```

`Invalid`には常に少なくとも1つのissueが含まれていなければなりません。実装ではprivateな構築ヘルパーによってこの不変条件を保証すべきです。この不変条件だけを目的として専用の非空コレクション型を導入する必要はありません。ただし、パッケージの他の部分も改善するなら導入しても構いません。

`Validation`はパッケージ外からreadonlyです。利用者はパターンマッチングで分解できますが、`Valid`または`Invalid`を構築できるのはこのパッケージだけです。これにより、外部で`Invalid([])`を構築することを防げます。

`Valid`はデコード済みの値を保持しません。検証は、その呼び出しにおいて指定されたすべてのチェックが成功したことだけを確立します。

```moonbit
pub trait LensTrait {
  fn check(Self, Json) -> Unit raise LensError
}

pub impl[T] LensTrait for Lens[T]

pub impl LensTrait for ObjectLens

pub fn validate(
  Json,
  Array[&LensTrait],
) -> Validation
```

`LensTrait`は意図的な型消去境界です。readonlyかつsealedであり、このパッケージだけが実装を定義できます。その唯一のメソッドはlensのトラバーサルとdecoderを実行し、成功した値を破棄し、発生した`Issue`を集約用に保持します。MoonBitは各異種結果型を保持する型パラメーター付きtrait objectを表現できないため、型付き`get`は`Lens[T]`、`PresenceLens[T]`、`ObjectLens`に残ります。

```moonbit
let user = object("user")
let name_lens = user.string("name")
let age_lens = user.int("age")

match validate(document, [user, name_lens, age_lens]) {
  Valid => {
    let name : String = name_lens.get(document)
    let age : Int = age_lens.get(document)
    consume(name, age)
  }
  Invalid(issues) => report(issues)
}
```

validatorは配列順にチェックを評価し、同じ決定的な順序でissueを返します。MoonBitのstruct、tuple、enum、その他のアプリケーション値を構築することはありません。

## 後続のcombinator

### Refinement

Refinementはデコードされた型を維持し、値の制約を追加します。

```text
Decoder[T] + (T -> Bool) -> Decoder[T]
```

公開APIでは安定した制約コードを必須とし、診断メッセージを受け付けても構いません。

### Transformation

Transformationはデコードされた型を変更します。

```text
Decoder[A] + (A -> B raise DecodeProblem) -> Decoder[B]
```

Transformationは`Decoder`に属し、利用価値が明確に向上する場合に限り`Lens`上の転送用便利APIを提供します。

### Arrays

配列サポートには次が必要です。

- `Array[T]`用のdecoder。
- indexを含むitem-level pointer。
- 最小、最大、空でない制約。
- すべてのitem issueを蓄積するか、最初の失敗で停止するかの明確な選択。

推奨されるデフォルトは、index順に独立したitem issueをすべて蓄積することです。このパッケージはすでに検証用途を対象としているためです。

### Value alternatives

`Decoder::one_of2`は、同じ選択済み値に複数のdecoderを適用します。すべてのalternativeが失敗した場合は、失敗をalternativeごとにグループ化し、区別できないリストに平坦化しないようにします。

異なる出力型は、組み合わせる前に明示的なMoonBit enumへマッピングする必要があります。

### Discriminated unions

Discriminated-union decoderはdiscriminatorを一度デコードし、同一の型を出力する1つの`Case[T]`を選択します。各caseは同じ出力型を生成しなければなりません。通常はアプリケーションenumであり、その結果の`Lens[T]`は静的に型付けされたままです。

この機能は型付きlens decodingに属し、集約検証には属しません。case選択には明示的なオブジェクト境界が必要なため、通常のobject lensが存在した後に設計すべきです。

### Unknown fields

Unknown-field拒否は、将来の宣言的object checkに属します。

| Policy   | Behavior                 |
| -------- | ------------------------ |
| `strict` | 未宣言のキーを拒否する。 |

`strip_unknown`と`passthrough`は変換ポリシーであり、検証ポリシーではありません。必要になった場合は、明示的な変換後出力を持つ別APIが必要であり、`Validation`の意味を変更してはいけません。

JSON SchemaとOpenAPIの生成は、サポートされる制約ごとに宣言的メタデータが必要な別提案として扱います。

## 構築とソース変更の分離

`Lens::set`が変更するのは`JsonBuilder`の対象だけです。既存の`Json`を受け付けないため、欠落した親はbuilder所有のオブジェクトノードとして明確に作成され、ソースのaliasingポリシーは不要です。

このbuilder契約は、以前に提案されたソース変更マイルストーンを意図的に置き換えます。ソースドキュメントの更新が必要になった場合は、永続更新ポリシーとlens-lawテストを備えた、別名のAPIが必要です。builder対象の`Lens::set`の意味を変更してはいけません。

## 提供ロードマップ

### マイルストーン1: Selection foundation

- RFC 6901表示を備えた不透明な`Pointer`。
- `JsonKind`、`IssueCode`、`Issue`、`LensError`。
- 正確な失敗位置を持つキー専用lookup。
- `Decoder[T]`、`Lens[Map[String, Json]]`を内部に持つ`ObjectLens`、`Lens[T]`。
- 文字列、boolean、number、integer、raw JSON decoder。
- `Lens::get`。

終了条件:

- 公開例がコンパイルできる。
- プリミティブの成功と失敗の動作がテストされている。
- すべてのトラバーサル失敗が正確な失敗pointerを報告する。
- fractional、範囲外、非有限の整数ケースが`Double::to_int()`の意味論に従う。
- 数値テストはパッケージ固有のparserではなく、委譲された標準変換の境界を検証する。

### マイルストーン2: Aggregate validation

- 非ジェネリックな`Validation`。
- `Lens[T]`、`PresenceLens[T]`、`ObjectLens`が実装するチェック専用`LensTrait`。
- trait-object aggregate `validate`。
- 決定的なエラー順序。
- 安定した制約コードを持つrefinement。

終了条件:

- すべてのチェックが検証呼び出しごとに1回評価される。
- 複数の独立したフィールドissueがまとめて返される。
- 成功した検証は、型付き値を構築またはキャッシュせずに`Valid`を返す。
- 呼び出し側は、元の`Lens[T]`値を通じて検証済みデータへアクセスし続ける。

### マイルストーン3: Presence and collections

- `optional`、`nullable`、`nullish`。
- デフォルトでは欠落値にだけ適用される`default`。
- index付きpointerを持つ配列item decoding。
- 配列長制約。
- Transformation。

終了条件:

- 欠落/null truth tableがカバーされる。
- 配列issueの順序が決定的である。
- defaultが明示的な`null`や無効な存在値を隠さない。

### マイルストーン4: Alternatives and object checks

- `Decoder::one_ofN`。
- Discriminated unions。
- 宣言的オブジェクト境界。
- Unknown-field拒否。

JSON SchemaとOpenAPI生成は、サポートするすべての制約に宣言的メタデータが必要な、別の提案として扱います。

### マイルストーン5: Typed output construction

- サポートされる各decoderに対応する`Encoder[T]`。
- `ToJson`を実装する可変`JsonBuilder`。
- 生成されたオブジェクト親を備えたbuilder対象`Lens::set`。
- 明示的なoptional省略、nullable null、設定可能なnullish動作。
- path競合と表現できない省略に対する構造化失敗。

終了条件:

- プリミティブ、配列、optional、nullable値が文書化されたJSON出力を生成する。
- 繰り返し書き込みでは最新の値が使われる。
- optionalの削除が空の生成親をpruneする。
- pathとencodingの失敗が、builderを部分的に変更せず正確なpointerを報告する。
- 後のbuilder書き込み前に生成されたJSONが変更されない。

## 初期パッケージ構成

最初の実装は小さく保ちます。

```text
lens/
├── docs/
│   ├── design.md
│   └── design.ja.md
└── src/
    ├── pointer.mbt
    ├── issue.mbt
    ├── decoder.mbt
    ├── encoder.mbt
    ├── lens.mbt
    ├── lookup.mbt
    └── builder.mbt
```

マイルストーン2で`check.mbt`と`validation.mbt`を追加します。optionality、配列、alternative用のファイルは、各機能を実装するときにだけ追加します。

## マイルストーン1のテストマトリクス

- root propertyの成功。
- nested propertyの成功。
- root propertyの欠落。
- intermediate propertyの欠落。
- leaf propertyの欠落。
- key lensに対するnon-object root。
- non-object intermediate value。
- 文字列の型不一致。
- booleanの型不一致。
- numberの型不一致。
- `number`を通過する非有限数。
- `Double::to_int()`で変換されるfractional value。
- `Double::to_int()`で飽和する正負のoverflow。
- `Double::to_int()`で変換される非有限値。
- 正確な`@int.MIN_VALUE`と`@int.MAX_VALUE`の変換。
- すべてのプリミティブdecoderに明示的な`null`を渡す。
- `~`、`/`、空キーのJSON Pointer escaping。
- すべてのトラバーサルおよびデコード失敗について正しいpointer。
- 1つのlensを複数のドキュメントで再利用する。

## 保留中の決定

次の選択はマイルストーン1を妨げないため、実装上の証拠に基づいて解決します。

- `Issue`、`IssueCode`、`JsonKind`、`LensError`のpayloadを完全に公開するかreadonlyにするか。
- `Pointer`がsegmentを公開するか、iterationと文字列変換だけを公開するか。
- 配列item検証がデフォルトで失敗を蓄積するか、蓄積モードとfail-fastモードの両方を公開するか。
- 構造化されていないエラー分類にもかかわらず、`FromJson` bridgeが十分有用か。
- 将来の書き込みでpersistent updateまたはin-place updateを使うか。
- 欠落した中間オブジェクトをエラーとするか、明示的なwrite policyによって作成可能にするか。
- 書き込みが欠落値または`null`値を対象とする場合のoptionalおよびnullable lensの動作。

## References

- [MoonBit method and trait documentation](https://docs.moonbitlang.com/en/stable/language/methods.html)
- [MoonBit error handling documentation](https://docs.moonbitlang.com/en/stable/language/error-handling.html)
- [MoonBit deriving documentation](https://docs.moonbitlang.com/en/stable/language/derive.html)
- [MoonBit core JSON API](https://mooncakes.io/docs/moonbitlang/core/json)
- [MoonBit core string parsing API](https://mooncakes.io/docs/moonbitlang/core/string)
- [MoonBit `Double::to_int` implementation and semantics](https://mooncakes.io/assets/moonbitlang/core/builtin/double_to_int_wasm.mbt.html)
- [MoonBit core API index](https://mooncakes.io/docs/moonbitlang/core/)
- [RFC 6901: JSON Pointer](https://www.rfc-editor.org/rfc/rfc6901)
