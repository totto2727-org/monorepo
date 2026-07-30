# MoonBit向け型付きJSON Lensとバリデーション

## ステータス

このドキュメントは、将来の `lens` パッケージに向けたレビュー済み設計方針です。

この提案は、以下に記録された修正を反映した上で有効です。主要な公開抽象化は `Lens[T]` です。最初のリリースでは読み取り専用の機能のみを公開し、名前は将来の正当な `set` および `modify` APIのために意図的に予約されています。

このレビューは MoonBit 0.10.4 および `moonbitlang/core` 0.10.4 を対象としています。

## 決定の概要

- 読み取り専用の型付きJSONレンズとバリデーションライブラリから開始する。
- レンズを、パッケージが所有するJSONポインタと値デコーダとしてモデル化する。
- 型付き値には `Lens[T]` を、型付きオブジェクト値および子プロパティレンズを生成可能なパスには `ObjectLens` を使用する。
- パッケージのポインタ表現は `@json.JsonPath` から独立させる。
- 単一のレンズからは `LensError` を発生させ、集約チェックからは非ジェネリックな `Validation` を返す。
- 欠落プロパティと明示的なJSON `null` を異なる状態として保持する。
- `Lens[T]` と `ObjectLens` に静的な結果型を保持し、バリデーションは成功または蓄積された問題のみを報告する。
- チェック専用の `LensTrait` トレイトオブジェクトを使用して、集約バリデーションの境界でのみ具象レンズ型を消去する。
- オブジェクトプロパティとプリミティブデコーダから開始する。
- 数値のパースと変換はMoonBitコアAPIに委譲し、パッケージ固有の数値パーサーは維持しない。
- オプショナリティ、配列、リファインメント、変換、代替は、基盤が安定した後にのみ追加する。
- 不透明なデコーダクロージャからのJSON SchemaやOpenAPIの生成は保証しない。
- `set` と `modify` は、明示的な書き込みポリシーとレンズ則テストを伴う将来のマイルストーンに留保する。
- バリデーションAPIに値の構築、型推論、またはミューテーション操作を追加しない。

## 問題の定義

MoonBitの標準 `Json` 型はJSON値を表現し、その `FromJson` トレイトは完全な値をMoonBit型にデコードします。このパッケージは別のユースケースに対処します。すなわち、1つのJSONドキュメントから既知の位置を繰り返し選択し、選択した各値をデコードし、オプションですべての独立した失敗を1つのバリデーション結果に収集することです。

コアモデルは次のとおりです。

```text
ObjectLens
└── オブジェクトアクセサ: Lens[Map[String, Json]]

Lens[T]
├── 位置: Pointer
└── 値の解釈: Decoder[T]
```

最初のリリースは、意図的に汎用JSONクエリ言語、完全なHaskellレンズ実装、または `FromJson` 導出の置き換えではありません。将来のJSONレンズの読み取り側を確立し、ミューテーションを初期スコープから除外します。

## 元の提案を変更するレビュー結果

### 公開抽象化として `Lens` を維持する

従来のレンズは読み取りと正当な更新の両方をサポートします。最初のマイルストーンでは読み取りとデコードのみを実装しますが、将来の `set` および `modify` 操作は意図された設計空間の一部です。

したがって、パッケージと公開型は `lens` と `Lens[T]` を使用する必要があります。ドキュメントには、現在どの操作が利用可能かを明確に記載し、名前がミューテーションが既に存在することを暗示しないようにする必要があります。

### ポインタ表現を所有する

現在の `@json.JsonPath` インターフェースは抽象的な `JsonPath` 型と追加メソッドを公開していますが、公開されたルートコンストラクタは公開していません。主に `FromJson` と `JsonDecodeError` のために設計されています。

したがって、パッケージは独自の不透明な `Pointer` 型を必要とします。これはRFC 6901 JSON Pointerとしてレンダリングされ、安全な構築操作と検査操作のみを公開する必要があります。`@json.JsonPath` に依存すると、パッケージがルートパスを構築できなくなり、公開エラーモデルがコア内部に結合されてしまいます。

### トラバーサルが失敗した位置を報告する

ルックアップは、要求されたポインタと正常にトラバースされたプレフィックスの両方を追跡する必要があります。

`/user/profile/name` へのリクエストの場合:

- `name` が欠落している場合、`/user/profile/name` を報告する。
- `profile` が文字列の場合、`/user/profile` で型不一致を報告する。
- `user` が欠落している場合、`/user` を報告する。

すべての失敗に対して要求された完全なポインタを報告すると、中間の型エラーが誤って識別されます。

### 発生するエラーとバリデーションデータを分離する

`Lens::get` は `Result` を返すのではなく、パッケージ固有の `LensError` を発生させる必要があります。エラーは1つの `Issue` を保持します。`Issue` はプレーンな構造化値のままであるため、集約バリデーションは例外を収集手段として使用せずに多数の問題を保持できます。

この分離により、各型に1つの役割が与えられます:

- `LensError` は、`raise` および `catch` で使用される型付き制御フロー境界です。
- `Issue` は、ポインタ、安定したコード、およびオプションのメッセージを含む、検査可能な診断データです。

`CustomError` という名前は公開パッケージAPIとしては汎用的すぎます。`LensError(Issue)` は、所有する抽象化と再利用可能な診断ペイロードの両方を識別します。

### レンズに静的な型を保持する

MoonBitは、TypeScriptライブラリがZodスキーマ式から型を推論できるように、バリデーション定義の実行時コレクションからコンパイル時の結果型を導出することはできません。バリデーションAPIは、`Schema[T]`、固定アリティビルダー、または値を生成するバリデーション結果を使用してそのモデルを模倣してはなりません。

`Lens[T]` は、プリミティブ値および生のJSON値の静的な型情報のソースです。`ObjectLens` は `Lens[Map[String, Json]]` を所有するため、静的に型付けされたオブジェクトアクセスも提供します。集約バリデーションは、チェック専用の `LensTrait` トレイトオブジェクトを通じて両方を受け入れ、すべてのチェックを評価し、成功または蓄積された問題のみを返します。呼び出し元は明示的な変換を実行しません。バリデーション成功後も、元のレンズを通じて値を読み取り続けます。

これは意図的に、バリデーション後にアクセスするとトラバーサルとデコードが再度実行されることを意味します。その重複を回避するには、異種型付きキャッシュまたはアプリケーション固有の生成コードが必要になりますが、そのどちらも初期パッケージには含めるべきではありません。

### 数値変換をMoonBitコアに委譲する

パッケージはJSONトラバーサル、型選択、および構造化エラーマッピングを所有する必要がありますが、小数、指数、符号、オーバーフロー、または丸めアルゴリズムを所有するべきではありません。

`Json::Number` には、MoonBitコアが既に生成する `Double` 値を使用します。保持されているソーステキストを再パースしないでください。`Int` が要求された場合は、直接 `Double::to_int()` に委譲し、パッケージレベルのバリデーションなしでその標準的な変換動作を継承します。

後でデコーダが数値テキストを受け入れる場合は、`@string.from_str`、`@string.parse_double`、または `@string.parse_int` などの現在非推奨ではない標準エントリポイントにパースを委譲し、発生した標準エラーを `DecodeProblem` に変換します。レビュー済みのツールチェーンは、依然として `@strconv.parse_*` を非推奨の互換性APIとして公開しています。新しいパッケージコードは、サポートされている `@string` の代替を使用する必要があります。

手書きの数字ループ、数値文法を複製する正規表現、およびパッケージ固有の小数または指数パーサーは対象外です。これにより、標準ライブラリのセマンティクスとメンテナンスの重複を回避します。

### オプショナリティを公開する前にプレゼンスセマンティクスを設計する

欠落と `null` は区別されます:

| 入力状態 | 必須文字列 | オプション文字列 | Nullable文字列 | オプションNullable文字列 |
| -------- | ---------: | ---------------: | -------------: | -----------------------: |
| 欠落     |     エラー |           `None` |         エラー |                   `None` |
| `null`   |   型エラー |         型エラー |         `None` |                   `None` |
| 文字列   |         値 |    `Some(value)` |  `Some(value)` |            `Some(value)` |

オプションのNullable値を `lens.optional().nullable()` として実装しないでください。どちらの操作も出力をオプションに変更するため、単純な連鎖ではネストされたオプション型または曖昧なセマンティクスが生成されます。3つの明示的なコンビネータを使用します:

```moonbit
lens.optional()
lens.nullable()
lens.optional_nullable()
```

これらの操作は、正確なMoonBitシグネチャがコンパイルおよびテストされるまで延期されます。

### 値の代替を位置のフォールバックから分離する

`or` 操作は曖昧です。次のいずれかを意味する可能性があります:

- 同じ選択されたJSON値に対して別のデコーダを試す。
- 最初のレンズが失敗した場合に別の位置を試す。

設計では別々の名前を使用する必要があります:

```text
Decoder::one_of2     1つの値に対する代替
Lens::or_else        別の位置へのフォールバック（この機能が必要な場合）
```

初期のバリデーションロードマップに属するのは値の代替のみです。

### 未知フィールドのバリデーションにはオブジェクトメタデータが必要

独立した `LensTrait` チェックのみで構成されたバリデータは、オブジェクトに許可されるプロパティの完全なセットを認識しません。その結果、未知フィールドの拒否を初期の集約バリデータの単純なオプションとして正しく追加することはできません。

未知フィールドのバリデーションは、オブジェクトの境界と宣言されたキーを記録する明示的なオブジェクトチェック表現を待つ必要があります。`strip_unknown` と `passthrough` はデータを変換または返すため、バリデーション専用のAPIには属しません。

### スキーマ生成には宣言的デコーダメタデータが必要

不透明な述語および変換クロージャは、JSON SchemaやOpenAPIに確実に変換できません。ポインタとデコーダの分離は実装構造を改善しますが、スキーマ生成には十分ではありません。

スキーマ生成は、将来の設計で宣言的な制約モデルが導入されない限り、非目標です。

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

文字列形式はRFC 6901に従います:

- ルートは空の文字列としてレンダリングされます。
- キーは `/key` を追加します。
- `~` は `~0` としてエスケープされます。
- `/` は `~1` としてエスケープされます。
- 配列インデックスはその10進表現を追加します。

### Decoder

`Decoder[T]` は、既に選択された1つのJSON値を解釈します。ドキュメントのトラバーサルは実行しません。

```moonbit
pub struct Decoder[T] {
  priv decode_ : (Json) -> T raise DecodeProblem
}
```

`DecodeProblem` は、パスに依存しない失敗情報を含むパッケージプライベートなサブエラーです。`Lens::get` はそれをキャッチし、選択されたポインタをアタッチして公開の `Issue` を生成し、`LensError(issue)` を発生させます。

プリミティブデコーダはJSONバリアントディスパッチを直接実行する必要があり、パッケージが安定した構造化エラーコードを提供できるようにします。これらのデコーダ内部の数値パースと変換はMoonBitコアに委譲する必要があります。後で `Decoder::from_json[T : FromJson]` ブリッジが `JsonDecodeError` をキャッチする可能性がありますが、コアの人間可読メッセージは安定した構造化エラーコードではないため、その失敗は外部デコード失敗として分類する必要があります。

### オブジェクトレンズ

`ObjectLens` は、子プロパティが宣言される型付きオブジェクト位置を表します。トラバーサルとオブジェクトデコードを内部の `Lens[Map[String, Json]]` に委譲します。オブジェクトデコードは選択されたトップレベルのマップをコピーするため、返されたマップを通じたミューテーションはソースドキュメントを変更しません。ネストされた `Json` 値は標準の共有セマンティクスを保持します。

```moonbit
pub struct ObjectLens {
  priv lens : Lens[Map[String, Json]]
}
```

選択されたオブジェクトを `ObjectLens::get` を通じて返し、`Lens[String]` から子文字列プロパティを作成するなどの無効なAPIを防ぎます。

### 型付きレンズ

```moonbit
pub struct Lens[T] {
  priv pointer : Pointer
  priv decoder : Decoder[T]
}
```

`Lens::get` は2つの操作を実行します:

1. ドキュメントをレンズのポインタまでトラバースする。
2. 選択された値をそのデコーダでデコードする。

トラバーサルとデコードの失敗は、同じ公開 `Issue` 値に正規化され、`LensError` として発生します。

## フェーズ1の公開API

実装中に正確な宣言構文を確認する必要がありますが、意図されたAPIサーフェスは次のとおりです:

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

例:

```moonbit
fn read_name(document : Json) -> String raise LensError {
  object("user").object("profile").string("name").get(document)
}

let name : String = read_name(document)
```

## ルックアップセマンティクス

ルックアップはルートから開始され、正常なセグメントごとにトラバースされたポインタを記録します。

概念的には:

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

フェーズ1ではキーセグメントのみを構築しますが、内部の失敗位置ルールは既にテストでカバーされている必要があります。

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

最終的な可視性モードは制限される可能性がありますが、コンシューマーはテキストをパースせずにポインタとコードを検査できなければなりません。

`message` フィールドはオプションの診断コンテキストです。プログラムロジックは `message` ではなく `IssueCode` で分岐する必要があります。

ポインタは既に欠落プロパティを識別するため、エラーに冗長なプロパティ名フィールドは必要ありません。

`Issue` 自体はサブエラーではありません。`LensError` のペイロードとして保持することで、`Validation::Invalid` は `Array[Issue]` を直接格納でき、`Lens::get` の呼び出し元は引き続きMoonBitの型付きエラー伝播を使用できます。

## プリミティブデコードセマンティクス

### 文字列

`Json::String` のみを受け入れます。

### 真偽値

`Json::True` と `Json::False` のみを受け入れます。

### 数値

`Json::Number` のみを受け入れます。

フェーズ1の `number` デコーダは、有限性や範囲のバリデーションなしで、`Json::Number` によって既に格納されている `Double` を返します。保持されているテキスト表現を検査または再パースしません。

### 整数

JSONには数値型があり、個別の整数型はありません。`int` デコーダは、`Json::Number` によって既に格納されている `Double` に `Double::to_int()` を直接適用します。有限性、範囲、または整数精度のバリデーションは実行しないため、MoonBitの標準的な切り捨て、飽和、および特殊値の動作を継承します。パッケージはJSON数値テキスト自体をパースしてはなりません。

### 生のJSON

`json` デコーダは常に選択された値で成功します。

## 1つのレンズが `LensError` を発生させる理由

MoonBitはパッケージ定義のサブエラーに型付きの `raise` および `catch` 動作を提供します。`Lens::get` はそのネイティブ制御フローを使用するため、通常の読み取りは呼び出し元に `Result` のアンラップを強制せずに1つの失敗を伝播します。

集約バリデーションは値ベースのままです。`validate` は各チェックごとに独立して `LensError(issue)` をキャッチし、含まれている `Issue` を保持し、収集されたすべての問題を `Validation::Invalid` で返します。1つのチェックの失敗が他の独立したチェックの評価を妨げてはなりません。

## フェーズ2: 集約バリデーション

### Validation

```moonbit
pub enum Validation {
  Valid
  Invalid(Array[Issue])
}
```

`Invalid` は常に少なくとも1つの問題を含まなければなりません。実装はプライベートな構築ヘルパーを通じてこの不変条件を強制する必要があります。専用の非空コレクション型はオプションであり、パッケージの他の部分を改善しない限り、この不変条件のみのために導入すべきではありません。

`Validation` はパッケージ外部では読み取り専用です。コンシューマーはパターンマッチングを通じて分解できますが、このパッケージのみが `Valid` または `Invalid` を構築でき、`Invalid([])` の外部構築を防ぎます。

`Valid` はデコードされた値を保持しません。バリデーションは、その呼び出しに対して提供されたすべてのチェックが成功したことのみを確立します。

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

`LensTrait` は意図的な型消去境界です。読み取り専用かつ封印されているため、このパッケージのみが実装を定義できます。その唯一のメソッドはレンズのトラバーサルとデコーダを実行し、成功した値を破棄し、発生した `Issue` を集約のために保持します。MoonBitは各異種結果型を保持する型パラメータ化されたトレイトオブジェクトを表現できないため、型付きの `get` は `Lens[T]` と `ObjectLens` に残ります。

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

バリデータはチェックを配列順に評価し、同じ決定論的な順序で問題を返します。MoonBitの構造体、タプル、列挙型、またはその他のアプリケーション値を構築することはありません。

## 将来のコンビネータ

### リファインメント

リファインメントはデコードされた型を保持し、値の制約を追加します:

```text
Decoder[T] + (T -> Bool) -> Decoder[T]
```

公開APIは安定した制約コードを要求し、診断メッセージを受け入れる場合があります。

### 変換

変換はデコードされた型を変更します:

```text
Decoder[A] + (A -> B raise DecodeProblem) -> Decoder[B]
```

変換は `Decoder` に属し、使用感を実質的に改善する場合にのみ `Lens` に転送の便宜を提供します。

### 配列

配列サポートには以下が必要です:

- `Array[T]` 用のデコーダ。
- インデックスを含むアイテムレベルのポインタ。
- 最小、最大、および非空の制約。
- フェイルファストなアイテムデコードと全アイテム問題の蓄積の間の明確な選択。

推奨されるデフォルトは、パッケージが既にバリデーションユースケースを対象としているため、インデックス順にすべての独立したアイテム問題を蓄積することです。

### 値の代替

`Decoder::one_of2` は、同じ選択された値に複数のデコーダを適用します。すべての代替が失敗した場合、代替ごとにグループ化された失敗を保持し、区別できないリストにフラット化しないでください。

異なる出力型は、組み合わせの前に明示的なMoonBit列挙型にマッピングする必要があります。

### 判別共用体

判別共用体デコーダは、判別子を1回デコードし、1つの同種の `Case[T]` を選択する必要があります。すべてのケースは同じ出力型（通常はアプリケーションの列挙型）を生成する必要があるため、結果の `Lens[T]` は静的に型付けされたままになります。

この機能は型付きレンズデコードに属し、集約バリデーションには属しません。通常のオブジェクトレンズが存在した後に設計する必要があります。なぜなら、ケース選択には明示的なオブジェクト境界が必要だからです。

### 未知フィールド

未知フィールドの拒否は、将来の宣言的オブジェクトチェックに属します:

| ポリシー | 動作                             |
| -------- | -------------------------------- |
| `strict` | 宣言されていないキーを拒否する。 |

`strip_unknown` と `passthrough` はバリデーションポリシーではなく、変換ポリシーです。もし将来必要になった場合、明示的な変換出力を持つ別個のAPIが必要であり、`Validation` の意味を変更してはなりません。

## ミューテーションは延期されるが、除外されない

フェーズ1は `set` または `modify` を提供しません。

`Lens` という名前は、正当なミューテーションが後で追加される可能性があるため保持されます。書き込みを公開する前に、設計は以下を解決する必要があります:

- 欠落している中間オブジェクトを作成するかどうか。
- 更新が永続的かインプレースか。
- 範囲外の配列インデックスの動作。
- オプションおよびNullableレンズが書き込みとどのように相互作用するか。

ミューテーションが実装される場合、`get`、`set`、および `modify` は同じ `Lens[T]` 抽象化の操作として残るべきです。内部の書き込み実装は別のソースファイルに存在してもよく、`LensTrait` と `Validation` はバリデーション専用のままです。

正常にトラバース可能なすべてのソースについて、テストは標準のレンズ則をカバーする必要があります:

```text
get(set(source, value)) = value
set(source, get(source)) = source
set(set(source, first), second) = set(source, second)
```

欠落または互換性のないパスに対する失敗動作はAPI契約の一部であり、これらの法則が適用される前に指定する必要があります。

## 提供ロードマップ

### マイルストーン1: 選択の基盤

- RFC 6901レンダリングを備えた不透明な `Pointer`。
- `JsonKind`、`IssueCode`、`Issue`、および `LensError`。
- 正確な失敗位置を備えたキー専用ルックアップ。
- `Decoder[T]`、`Lens[Map[String, Json]]` によってバックアップされた `ObjectLens`、および `Lens[T]`。
- 文字列、真偽値、数値、整数、および生のJSONデコーダ。
- `Lens::get`。

終了基準:

- 公開サンプルがコンパイルされる。
- プリミティブの成功および失敗動作がテストされている。
- すべてのトラバーサル失敗が正確な失敗ポインタを報告する。
- 小数、範囲外、および非有限の整数ケースが `Double::to_int()` セマンティクスに従う。
- 数値テストは、パッケージ固有のパーサーではなく、委譲された標準変換の境界をテストする。

### マイルストーン2: 集約バリデーション

- 非ジェネリックな `Validation`。
- `Lens[T]` および `ObjectLens` によって実装されたチェック専用の `LensTrait`。
- トレイトオブジェクトの集約 `validate`。
- 決定論的なエラー順序。
- 安定した制約コードを備えたリファインメント。

終了基準:

- 各チェックがバリデーション呼び出しごとに1回評価される。
- 複数の独立したフィールド問題が一緒に返される。
- 成功したバリデーションは、型付き値を構築またはキャッシュせずに `Valid` を返す。
- 呼び出し元は、正常にバリデーションされたデータに元の `Lens[T]` 値を介して引き続きアクセスする。

### マイルストーン3: プレゼンスとコレクション

- `optional`、`nullable`、および `optional_nullable`。
- `default`（デフォルトでは欠落値にのみ適用）。
- インデックス付きポインタを使用した配列アイテムデコード。
- 配列長制約。
- 変換。

終了基準:

- 欠落/nullの真理値表がカバーされている。
- 配列の問題順序が決定論的である。
- デフォルトが明示的な `null` や無効な存在値を隠さない。

### マイルストーン4: 代替とオブジェクトチェック

- `Decoder::one_ofN`。
- 判別共用体。
- 宣言的なオブジェクト境界。
- 未知フィールドの拒否。

JSON SchemaとOpenAPIの生成は、サポートされるすべての制約に対して宣言的メタデータを必要とする別個の提案のままです。

### 将来のマイルストーン: 正当なミューテーション

- `Lens::set`。
- `Lens::modify`。
- 明示的な欠落パス、互換性のないパス、および配列インデックス書き込みポリシー。
- 永続的更新とインプレース更新の間の文書化された選択。
- 書き込み可能なすべてのレンズカテゴリに対するレンズ則テスト。

このマイルストーンは、実際の呼び出し元がミューテーションを必要とするまではオプションですが、公開の命名と内部ポインタモデルがそれを妨げないようにする必要があります。

## 初期パッケージレイアウト

最初の実装は小さく保ちます:

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

マイルストーン2で `check.mbt` と `validation.mbt` を追加します。オプショナリティ、配列、および代替のためのファイルは、それらの機能が実装されたときにのみ追加します。

## マイルストーン1のテストマトリックス

- ルートプロパティ成功。
- ネストされたプロパティ成功。
- 欠落しているルートプロパティ。
- 欠落している中間プロパティ。
- 欠落しているリーフプロパティ。
- キーレンズに対する非オブジェクトルート。
- 非オブジェクト中間値。
- 文字列型不一致。
- 真偽値型不一致。
- 数値型不一致。
- `number` によって通過する非有限数値。
- `Double::to_int()` によって変換される小数値。
- `Double::to_int()` によって飽和される正および負のオーバーフロー。
- `Double::to_int()` によって変換される非有限値。
- 正確な `@int.MIN_VALUE` および `@int.MAX_VALUE` 変換。
- すべてのプリミティブデコーダに渡される明示的な `null`。
- `~`、`/`、および空キーのJSON Pointerエスケープ。
- すべてのトラバーサルおよびデコード失敗に対する正しいポインタ。
- 複数のドキュメントに対する1つのレンズの再利用。

## 延期された決定

以下の選択はマイルストーン1をブロックせず、実装の証拠をもって解決されるべきです:

- `Issue`、`IssueCode`、`JsonKind`、および `LensError` のペイロードを完全公開にするか読み取り専用にするか。
- `Pointer` がセグメントを公開するか、反復と文字列変換のみを公開するか。
- 配列アイテムバリデーションがデフォルトで失敗を蓄積するか、蓄積モードとフェイルファストモードの両方を公開するか。
- `FromJson` ブリッジが、その構造化されていないエラー分類にもかかわらず十分に有用か。
- 将来の書き込みが永続的更新とインプレース更新のどちらを使用するか。
- 欠落している中間オブジェクトがエラーであるか、明示的な書き込みポリシーによって作成できるか。
- 書き込みが欠落または `null` 値を対象とする場合のオプションおよびNullableレンズの動作。

## 参考文献

- [MoonBitのメソッドとトレイトに関するドキュメント](https://docs.moonbitlang.com/en/stable/language/methods.html)
- [MoonBitのエラーハンドリングに関するドキュメント](https://docs.moonbitlang.com/en/stable/language/error-handling.html)
- [MoonBitの導出に関するドキュメント](https://docs.moonbitlang.com/en/stable/language/derive.html)
- [MoonBitコアJSON API](https://mooncakes.io/docs/moonbitlang/core/json)
- [MoonBitコア文字列パースAPI](https://mooncakes.io/docs/moonbitlang/core/string)
- [MoonBit `Double::to_int` の実装とセマンティクス](https://mooncakes.io/assets/moonbitlang/core/builtin/double_to_int_wasm.mbt.html)
- [MoonBitコアAPIインデックス](https://mooncakes.io/docs/moonbitlang/core/)
- [RFC 6901: JSON Pointer](https://www.rfc-editor.org/rfc/rfc6901)
