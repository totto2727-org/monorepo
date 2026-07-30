# Typed JSON Lens and Validation for MoonBit

## ステータス

本ドキュメントは、将来の `lens` パッケージに向けたレビュー済みの設計方針です。

本提案は、以下に記録された修正を経て実現可能です。主要な公開抽象化は `Lens[T]` です。最初のリリースでは読み取り側のみを公開し、名前は将来の正当な `set` および `modify` API のために意図的に予約しています。

本レビューは MoonBit 0.10.4 および `moonbitlang/core` 0.10.4 を対象としています。

## 決定概要

- 読み取り専用の型付き JSON レンズおよびバリデーションライブラリから開始する。
- レンズをパッケージ所有の JSON ポインタに値デコーダを組み合わせたものとしてモデル化する。
- 型付き値には `Lens[T]` を、型付きオブジェクト値および子プロパティレンズを生成可能なパスには `ObjectLens` を使用する。
- パッケージのポインタ表現は `@json.JsonPath` から独立させる。
- 単一レンズからは `LensError` を発生させ、集約チェックからは非ジェネリックな `Validation` を返す。
- 欠落プロパティと明示的な JSON `null` を異なる状態として保持する。
- `Lens[T]` および `ObjectLens` の静的結果型を維持し、バリデーションは成功または蓄積された問題のみを報告する。
- チェック専用の `LensTrait` トレイトオブジェクトを使用して、集約バリデーションの境界でのみ具体的なレンズ型を消去する。
- オブジェクトプロパティとプリミティブデコーダから開始する。
- 数値のパースと変換は MoonBit コア API に委譲し、パッケージ固有の数値パーサを維持しない。
- オプショナリティ、配列、リファインメント、変換、代替は基盤が安定した後にのみ追加する。
- 不透明なデコーダクロージャからの JSON Schema や OpenAPI 生成は約束しない。
- `set` および `modify` は、明示的な書き込みポリシーとレンズ則テストを伴う将来のマイルストーンに留保する。
- バリデーションAPIに値の構築、型推論、または変更操作を追加しない。

## 問題提起

MoonBit の標準 `Json` 型は JSON 値を表現し、その `FromJson` トレイトは完全な値を MoonBit 型にデコードします。本パッケージは異なるユースケースに対処します。すなわち、1つの JSON ドキュメントから既知の位置を繰り返し選択し、各選択値をデコードし、オプションですべての独立した障害を1つのバリデーション結果に収集することです。

コアモデルは以下の通りです：

```text
ObjectLens
└── object accessor: Lens[Map[String, Json]]

Lens[T]
├── location: Pointer
└── value interpretation: Decoder[T]
```

最初のリリースは、意図的に汎用 JSON クエリ言語、完全な Haskell レンズ実装、または `FromJson` 導出の置き換えではありません。将来の JSON レンズの読み取り側を確立しつつ、変更を初期スコープから除外します。

## 元の提案を変更するレビュー所見

### `Lens` を公開抽象化として維持する

従来のレンズは読み取りと正当な更新の両方をサポートします。最初のマイルストーンは読み取りとデコードのみを実装しますが、将来の `set` および `modify` 操作は意図された設計領域の一部です。

したがって、パッケージと公開型は `lens` および `Lens[T]` を使用すべきです。ドキュメントは現在どの操作が利用可能かを明確に記載し、名前が既に変更が存在することを暗示しないようにしなければなりません。

### ポインタ表現を所有する

現在の `@json.JsonPath` インターフェースは抽象的な `JsonPath` 型と追加メソッドを公開していますが、公開ルートコンストラクタは公開していません。これは主に `FromJson` および `JsonDecodeError` 向けに設計されています。

したがって、パッケージは独自の不透明な `Pointer` 型を必要とします。これは RFC 6901 JSON Pointer としてレンダリングされ、安全な構築操作と検査操作のみを公開する必要があります。`@json.JsonPath` に依存すると、パッケージがルートパスを構築できなくなり、公開エラーモデルがコア内部に結合されてしまいます。

### トラバーサルが失敗した位置を報告する

ルックアップは、要求されたポインタと正常にトラバースされたプレフィックスの両方を追跡する必要があります。

`/user/profile/name` へのリクエストの場合：

- `name` が存在しない場合、`/user/profile/name` を報告する。
- `profile` が文字列の場合、`/user/profile` での型不一致を報告する。
- `user` が存在しない場合、`/user` を報告する。

すべての失敗に対して要求された完全なポインタを報告すると、中間の型エラーが誤って識別されます。

### 発生するエラーとバリデーションデータを分離する

`Lens::get` は `Result` を返すのではなく、パッケージ固有の `LensError` を発生させるべきです。エラーは1つの `Issue` を保持します。これはプレーンな構造化値のままであり、集約バリデーションが例外を収集手段として使用せずに多くの問題を保持できるようにします。

この分離により、各型に1つの役割が与えられます：

- `LensError` は、`raise` および `catch` で使用される型付き制御フロー境界です。
- `Issue` は、ポインタ、安定したコード、およびオプションのメッセージを含む、検査可能な診断データです。

公開パッケージ API としては `CustomError` という名前は汎用的すぎます。`LensError(Issue)` は、所有する抽象化と再利用可能な診断ペイロードの両方を識別します。

### レンズの静的型を維持する

MoonBit は、TypeScript ライブラリが Zod スキーマ式から型を推論できるように、実行時のバリデーション定義のコレクションからコンパイル時の結果型を導出できません。バリデーション API は、`Schema[T]`、固定アリティのビルダー、または値を生成するバリデーション結果を用いてそのモデルを模倣してはなりません。

`Lens[T]` は、プリミティブ値および生の JSON 値に対する静的な型情報の源泉です。`ObjectLens` は `Lens[Map[String, Json]]` を所有するため、静的に型付けされたオブジェクトアクセスも提供します。集約バリデーションは、チェック専用の `LensTrait` トレイトオブジェクトを通じて両方を受け入れ、すべてのチェックを評価し、成功または蓄積された問題のみを返します。呼び出し側は明示的な変換を実行しません。バリデーション成功後も、元のレンズを通じて値を読み取り続けます。

これは意図的に、バリデーション後にアクセスするとトラバーサルとデコードが再度実行されることを意味します。その重複を回避するには、異種型付きキャッシュまたはアプリケーション固有の生成コードが必要であり、そのいずれも初期パッケージに含めるべきではありません。

### 数値変換を MoonBit コアに委譲する

パッケージは JSON トラバーサル、型選択、および構造化エラーマッピングを所有すべきですが、10進数、指数、符号、オーバーフロー、または丸めアルゴリズムを所有すべきではありません。

`Json::Number` については、MoonBit コアが既に生成する `Double` 値を使用してください。保持されているソーステキストを再パースしないでください。`Int` が要求された場合は、`Double::to_int()` に直接委譲し、パッケージレベルのバリデーションなしでその標準的な変換動作を継承してください。

後でデコーダが数値テキストを受け入れる場合は、`@string.from_str`、`@string.parse_double`、または `@string.parse_int` などの現在非推奨でない標準エントリポイントにパースを委譲し、発生した標準エラーを `DecodeProblem` に変換してください。レビュー対象のツールチェーンはまだ `@strconv.parse_*` を非推奨の互換性APIとして公開しています。新しいパッケージコードは、サポートされている `@string` の代替を使用すべきです。

手書きの数字ループ、数値文法を複製する正規表現、およびパッケージ固有の10進数や指数パーサは対象外です。これにより、標準ライブラリのセマンティクスとメンテナンスの重複を回避します。

### オプショナリティを公開する前に存在セマンティクスを設計する

欠落と `null` は異なります：

| 入力状態 | 必須文字列 | オプション文字列 | Nullable 文字列 | オプション nullable 文字列 |
| ----------- | --------------: | --------------: | --------------: | -----------------------: |
| 欠落     |           error |          `None` |           error |                   `None` |
| `null`      |      type error |      type error |          `None` |                   `None` |
| 文字列      |           value |   `Some(value)` |   `Some(value)` |            `Some(value)` |

オプション nullable 値を `lens.optional().nullable()` として実装しないでください。両方の操作が出力を option に変更するため、単純な連鎖ではネストした option 型または曖昧なセマンティクスが生成されます。代わりに3つの明示的なコンビネータを使用してください：

```moonbit
lens.optional()
lens.nullable()
lens.optional_nullable()
```

これらの操作は、正確な MoonBit シグネチャがコンパイルおよびテストされるまで延期されます。

### 値の代替と位置のフォールバックを分離する

`or` 操作は曖昧です。以下のいずれかを意味します：

- 同じ選択された JSON 値に対して別のデコーダを試す。
- 最初のレンズが失敗した場合に別の位置を試す。

設計では別々の名前を使用する必要があります：

```text
Decoder::one_of2     1つの値に対する代替
Lens::or_else        別の位置へのフォールバック（この機能が必要な場合）
```

初期のバリデーションロードマップに属するのは値の代替のみです。

### 未知フィールドのバリデーションにはオブジェクトメタデータが必要

独立した `LensTrait` チェックのみから構成されるバリデータは、オブジェクトの許容プロパティの完全なセットを知りません。その結果、未知フィールドの拒否を初期の集約バリデータの単純なオプションとして正しく追加することはできません。

未知フィールドのバリデーションは、オブジェクト境界と宣言されたキーを記録する明示的なオブジェクトチェック表現を待つ必要があります。`strip_unknown` および `passthrough` はデータを変換または返すため、バリデーション専用の API には属しません。

### スキーマ生成には宣言的デコーダメタデータが必要

不透明な述語クロージャおよび変換クロージャは、JSON Schema または OpenAPI に確実に変換できません。ポインタとデコーダの分離は実装構造を改善しますが、スキーマ生成には十分ではありません。

スキーマ生成は、後の設計で宣言的制約モデルが導入されない限り、非目標です。

## アーキテクチャ

### Pointer

`Pointer` は不透明なパッケージ型です。内部では順序付けられたパスセグメントを格納します。

```moonbit
priv enum PointerSegment {
  Key(String)
  Index(Int)
}

pub struct Pointer {
  priv segments : Array[PointerSegment]
}
```

フェーズ1ではキートラバーサルのみが公開されます。インデックストラバーサルは配列サポートとともに公開されます。

文字列表現は RFC 6901 に従います：

- ルートは空文字列としてレンダリングされます。
- キーは `/key` を追加します。
- `~` は `~0` としてエスケープされます。
- `/` は `~1` としてエスケープされます。
- 配列インデックスはその10進表現を追加します。

### Decoder

`Decoder[T]` は既に選択された1つの JSON 値を解釈します。ドキュメントのトラバーサルは実行しません。

```moonbit
pub struct Decoder[T] {
  priv decode_ : (Json) -> T raise DecodeProblem
}
```

`DecodeProblem` はパスに依存しない障害情報を含むパッケージプライベートなサブエラーです。`Lens::get` はそれをキャッチし、選択されたポインタをアタッチして公開 `Issue` を生成し、`LensError(issue)` を発生させます。

プリミティブデコーダは JSON バリアントディスパッチを直接実行し、パッケージが安定した構造化エラーコードを提供できるようにする必要があります。これらのデコーダ内の数値パースと変換は MoonBit コアに委譲しなければなりません。後で `Decoder::from_json[T : FromJson]` ブリッジが `JsonDecodeError` をキャッチするかもしれませんが、コアの人間可読メッセージは安定した構造化エラーコードではないため、その失敗は外部デコード失敗として分類すべきです。

### Object lens

`ObjectLens` は、子プロパティが宣言可能な型付きオブジェクト位置を表します。トラバーサルとオブジェクトデコードを内部の `Lens[Map[String, Json]]` に委譲します。

```moonbit
pub struct ObjectLens {
  priv lens : Lens[Map[String, Json]]
}
```

`ObjectLens::get` を通じて選択されたオブジェクトを返し、`Lens[String]` から子文字列プロパティを作成するなどの無効な API を防止します。

### Typed lens

```moonbit
pub struct Lens[T] {
  priv pointer : Pointer
  priv decoder : Decoder[T]
}
```

`Lens::get` は2つの操作を実行します：

1. ドキュメントをレンズのポインタまでトラバースする。
2. 選択された値をそのデコーダでデコードする。

トラバーサル障害とデコード障害は、同じ公開 `Issue` 値に正規化され、`LensError` として発生します。

## フェーズ1 公開API

実装中に正確な宣言構文を確認する必要がありますが、意図された API サーフェスは以下の通りです：

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
```

`object("user")` は `root().object("user")` の便利なエイリアスです。

例：

```moonbit
fn read_name(document : Json) -> String raise LensError {
  object("user").object("profile").string("name").get(document)
}

let name : String = read_name(document)
```

## ルックアップセマンティクス

ルックアップはルートから開始し、各成功セグメントの後にトラバースされたポインタを記録します。

概念的には：

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

フェーズ1ではキーセグメントのみを構築しますが、内部の失敗位置ルールは既にテストでカバーされていなければなりません。

## エラーモデル

エラーは構造化データであり、事前にフォーマットされた文字列ではありません。

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

最終的な可視性モードは狭められる可能性がありますが、コンシューマはテキストを解析せずにポインタとコードを検査できなければなりません。

`message` フィールドはオプションの診断コンテキストです。プログラムロジックは `message` ではなく `IssueCode` で分岐すべきです。

ポインタは既に欠落プロパティを識別しているため、エラーに冗長なプロパティ名フィールドは必要ありません。

`Issue` 自体はサブエラーではありません。`LensError` のペイロードとして維持することで、`Validation::Invalid` が `Array[Issue]` を直接格納できる一方、`Lens::get` の呼び出し側は MoonBit の型付きエラー伝播を引き続き使用できます。

## プリミティブデコードセマンティクス

### 文字列

`Json::String` のみを受け入れます。

### 真偽値

`Json::True` および `Json::False` のみを受け入れます。

### 数値

`Json::Number` のみを受け入れます。

フェーズ1の `number` デコーダは、有限性や範囲のバリデーションなしで `Json::Number` が既に格納している `Double` を返します。保持されているテキスト表現を検査または再パースしません。

### 整数

JSON には数値型があり、整数型は独立して存在しません。`int` デコーダは `Double::to_int()` を `Json::Number` が既に格納している `Double` に直接適用します。有限性、範囲、または整数正確性のバリデーションを実行しないため、MoonBit の標準的な切り捨て、飽和、および特殊値の動作を継承します。パッケージは JSON 数値テキスト自体をパースしてはなりません。

### 生の JSON

`json` デコーダは選択された値で常に成功します。

## 1つのレンズが `LensError` を発生させる理由

MoonBit はパッケージ定義のサブエラーに型付きの `raise` および `catch` 動作を提供します。`Lens::get` はそのネイティブ制御フローを使用するため、通常の読み取りは呼び出し側に `Result` のアンラップを強制せずに1つの障害を伝播します。

集約バリデーションは値ベースのままです。`validate` は各チェックごとに独立して `LensError(issue)` をキャッチし、含まれている `Issue` を保持し、収集されたすべての問題を `Validation::Invalid` で返します。1つのチェックの失敗が、他の独立したチェックの評価を妨げてはなりません。

## フェーズ2 集約バリデーション

### Validation

```moonbit
pub enum Validation {
  Valid
  Invalid(Array[Issue])
}
```

`Invalid` は常に少なくとも1つの問題を含まなければなりません。実装はプライベートな構築ヘルパーを通じてこの不変条件を強制すべきです。専用の非空コレクション型はオプションであり、パッケージの他の部分を改善しない限り、この不変条件のみのために導入すべきではありません。

`Validation` はパッケージ外部では読み取り専用です。コンシューマはパターンマッチングを通じて分解できますが、`Valid` または `Invalid` を構築できるのはこのパッケージのみであり、`Invalid([])` の外部構築を防止します。

`Valid` はデコードされた値を保持しません。バリデーションは、その呼び出しに対して提供されたすべてのチェックが成功したことのみを確立します。

```moonbit
pub(open) trait LensTrait {
  fn check(Self, Json) -> Unit raise LensError
}

pub impl[T] LensTrait for Lens[T]

pub impl LensTrait for ObjectLens

pub fn validate(
  Json,
  Array[&LensTrait],
) -> Validation
```

`LensTrait` は意図的な型消去の境界です。その唯一のメソッドはレンズのトラバーサルとデコーダを実行し、成功値を破棄し、発生した `Issue` を集約のために保持します。MoonBit は各異種結果型を保持する型パラメータ化されたトレイトオブジェクトを表現できないため、型付きの `get` は `Lens[T]` および `ObjectLens` に残ります。

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

バリデータはチェックを配列順に評価し、同じ決定論的顺序で問題を返します。MoonBit の構造体、タプル、列挙型、またはその他のアプリケーション値を構築することはありません。

## 将来のコンビネータ

### リファインメント

リファインメントはデコードされた型を維持し、値の制約を追加します：

```text
Decoder[T] + (T -> Bool) -> Decoder[T]
```

公開APIは安定した制約コードを要求し、診断メッセージを受け入れてもよいです。

### 変換

変換はデコードされた型を変更します：

```text
Decoder[A] + (A -> B raise DecodeProblem) -> Decoder[B]
```

変換は `Decoder` に属し、使用感を実質的に向上させる場合にのみ `Lens` に転送の便宜を提供します。

### 配列

配列サポートには以下が必要です：

- `Array[T]` 用のデコーダ。
- インデックスを含むアイテムレベルのポインタ。
- 最小、最大、および非空の制約。
- フェイルファストなアイテムデコードと全アイテム問題の蓄積の間の明確な選択。

パッケージが既にバリデーションユースケースを対象としているため、推奨されるデフォルトはすべての独立したアイテム問題をインデックス順に蓄積することです。

### 値の代替

`Decoder::one_of2` は同じ選択された値に複数のデコーダを適用します。すべての代替が失敗した場合、失敗を区別できないリストに平坦化するのではなく、代替ごとにグループ化して保持します。

異なる出力型は、組み合わせの前に明示的な MoonBit 列挙型にマッピングされなければなりません。

### 判別共用体

判別共用体デコーダは、識別子を1回デコードし、1つの均質な `Case[T]` を選択する必要があります。すべてのケースは同じ出力型（通常はアプリケーション列挙型）を生成する必要があり、結果の `Lens[T]` は静的に型付けされたままになります。

この機能は型付きレンズデコードに属し、集約バリデーションには属しません。ケース選択には明示的なオブジェクト境界が必要なため、通常のオブジェクトレンズが存在した後に設計されるべきです。

### 未知フィールド

未知フィールドの拒否は、将来の宣言的オブジェクトチェックに属します：

| ポリシー    | 動作                |
| -------- | ----------------------- |
| `strict` | 宣言されていないキーを拒否する。 |

`strip_unknown` および `passthrough` は変換ポリシーであり、バリデーションポリシーではありません。これらが将来必要になった場合、明示的な変換出力を持つ別個のAPIが必要であり、`Validation` の意味を変更してはなりません。

## 変更は延期されており、除外されていない

フェーズ1は `set` または `modify` を提供しません。

`Lens` という名前は、将来正当な変更が追加される可能性があるために維持されています。書き込みを公開する前に、設計は以下を解決しなければなりません：

- 欠落している中間オブジェクトを作成するかどうか。
- 更新が永続的かインプレースか。
- 範囲外の配列インデックスがどのように動作するか。
- オプショナルレンズと Nullable レンズが書き込みとどのように相互作用するか。

変更が実装される場合、`get`、`set`、および `modify` は同じ `Lens[T]` 抽象化の操作として残るべきです。内部の書き込み実装は別のソースファイルに存在してもよく、`LensTrait` および `Validation` はバリデーション専用のままです。

正常にトラバース可能なすべてのソースについて、テストは標準的なレンズ則をカバーする必要があります：

```text
get(set(source, value)) = value
set(source, get(source)) = source
set(set(source, first), second) = set(source, second)
```

欠落または互換性のないパスの失敗動作は API 契約の一部であり、これらの法則が適用される前に指定されなければなりません。

## 提供ロードマップ

### マイルストーン1: 選択基盤

- RFC 6901 レンダリングを備えた不透明な `Pointer`。
- `JsonKind`、`IssueCode`、`Issue`、および `LensError`。
- 正確な失敗位置を備えたキー専用ルックアップ。
- `Lens[Map[String, Json]]` によって支えられた `Decoder[T]`、`ObjectLens`、および `Lens[T]`。
- 文字列、真偽値、数値、整数、および生の JSON デコーダ。
- `Lens::get`。

完了基準：

- 公開サンプルがコンパイルされる。
- プリミティブの成功および失敗動作がテストされている。
- すべてのトラバーサル障害が正確な失敗ポインタを報告する。
- 小数、範囲外、および非有限の整数ケースが `Double::to_int()` セマンティクスに従う。
- 数値テストは、パッケージ固有のパーサではなく、委譲された標準変換の境界をテストする。

### マイルストーン2: 集約バリデーション

- 非ジェネリックな `Validation`。
- `Lens[T]` および `ObjectLens` によって実装されたチェック専用の `LensTrait`。
- トレイトオブジェクト集約 `validate`。
- 決定論的エラー順序付け。
- 安定した制約コードによるリファインメント。

完了基準：

- 各チェックがバリデーション呼び出しごとに1回評価される。
- 複数の独立したフィールド問題が一緒に返される。
- 成功したバリデーションは、型付き値を構築またはキャッシュせずに `Valid` を返す。
- 呼び出し側は、元の `Lens[T]` 値を介して正常にバリデーションされたデータに引き続きアクセスする。

### マイルストーン3: 存在とコレクション

- `optional`、`nullable`、および `optional_nullable`。
- `default`、デフォルトでは欠落値にのみ適用される。
- インデックス付きポインタによる配列アイテムデコード。
- 配列長制約。
- 変換。

完了基準：

- 欠落/null の真理値表がカバーされている。
- 配列問題の順序が決定論的である。
- デフォルトが明示的な `null` や無効な現在値を隠すことがない。

### マイルストーン4: 代替とオブジェクトチェック

- `Decoder::one_ofN`。
- 判別共用体。
- 宣言的オブジェクト境界。
- 未知フィールドの拒否。

JSON Schema および OpenAPI の生成は、サポートされるすべての制約に対して宣言的メタデータを必要とする別個の提案として残ります。

### 将来のマイルストーン: 正当な変更

- `Lens::set`。
- `Lens::modify`。
- 明示的な欠落パス、非互換パス、および配列インデックスの書き込みポリシー。
- 永続的更新とインプレース更新の間の文書化された選択。
- 書き込み可能なすべてのレンズカテゴリに対するレンズ則テスト。

このマイルストーンは、実際の呼び出し側が変更を必要とするまでオプションですが、公開命名と内部ポインタモデルはそれを妨げてはなりません。

## 初期パッケージレイアウト

最初の実装は小さく保ちます：

```text
lens/
├── docs/
│   ├── design.md
│   └── design.ja.md
└── src/
    ├── pointer.mbt
    ├── issue.mbt
    ├── decoder.mbt
    ├── lens.mbt
    └── lookup.mbt
```

`check.mbt` と `validation.mbt` はマイルストーン2で追加します。オプショナリティ、配列、および代替のファイルは、それらの機能が実装されたときにのみ追加します。

## マイルストーン1のテストマトリックス

- ルートプロパティ成功。
- ネストされたプロパティ成功。
- 欠落ルートプロパティ。
- 欠落中間プロパティ。
- 欠落リーフプロパティ。
- キーレンズに対する非オブジェクトルート。
- 非オブジェクト中間値。
- 文字列型不一致。
- 真偽値型不一致。
- 数値型不一致。
- `number` によって通過される非有限数値。
- `Double::to_int()` によって変換される小数値。
- `Double::to_int()` によって飽和される正および負のオーバーフロー。
- `Double::to_int()` によって変換される非有限値。
- 正確な `@int.MIN_VALUE` および `@int.MAX_VALUE` 変換。
- すべてのプリミティブデコーダに渡される明示的な `null`。
- `~`、`/`、および空キーの JSON Pointer エスケープ。
- すべてのトラバーサルおよびデコード障害に対する正しいポインタ。
- 複数のドキュメントに対して1つのレンズを再利用する。

## 延期された決定

以下の選択肢はマイルストーン1をブロックせず、実装の証拠をもとに解決されるべきです：

- `Issue`、`IssueCode`、`JsonKind`、および `LensError` のペイロードを完全公開にするか読み取り専用にするか。
- `Pointer` がそのセグメントを公開するか、反復と文字列変換のみを公開するか。
- 配列アイテムバリデーションがデフォルトで失敗を蓄積するか、蓄積モードとフェイルファストモードの両方を公開するか。
- `FromJson` ブリッジが、その構造化されていないエラー分類にもかかわらず十分に有用か。
- 将来の書き込みが永続的更新とインプレース更新のどちらを使用するか。
- 欠落している中間オブジェクトがエラーであるか、明示的な書き込みポリシーによって作成可能か。
- オプショナルレンズと Nullable レンズが、書き込みが欠落値または `null` 値を対象とする場合にどのように動作するか。

## 参考文献

- [MoonBit メソッドおよびトレイトドキュメント](https://docs.moonbitlang.com/en/stable/language/methods.html)
- [MoonBit エラーハンドリングドキュメント](https://docs.moonbitlang.com/en/stable/language/error-handling.html)
- [MoonBit 導出ドキュメント](https://docs.moonbitlang.com/en/stable/language/derive.html)
- [MoonBit コア JSON API](https://mooncakes.io/docs/moonbitlang/core/json)
- [MoonBit コア文字列パース API](https://mooncakes.io/docs/moonbitlang/core/string)
- [MoonBit `Double::to_int` 実装およびセマンティクス](https://mooncakes.io/assets/moonbitlang/core/builtin/double_to_int_wasm.mbt.html)
- [MoonBit コア API インデックス](https://mooncakes.io/docs/moonbitlang/core/)
- [RFC 6901: JSON Pointer](https://www.rfc-editor.org/rfc/rfc6901)