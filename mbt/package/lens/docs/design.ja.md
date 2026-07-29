# MoonBit向け型付きJSON Lensとバリデーション

## ステータス

このドキュメントは、将来の `lens` パッケージに向けたレビュー済み設計方針です。

以下に記録された修正後の提案は実行可能です。その主要な公開抽象化は `Lens[T]` です。最初のリリースでは読み取り側のみを公開し、名前は将来の lawful な `set` および `modify` API を意図的に予約します。

このレビューは MoonBit 0.10.4 および `moonbitlang/core` 0.10.4 を対象としています。

## 決定概要

- 読み取り専用の型付きJSON Lensおよびバリデーションライブラリから開始する。
- Lensを、パッケージ所有のJSON Pointerと値デコーダの組み合わせとしてモデル化する。
- 公開型付き抽象化には `Lens[T]` を、子プロパティLensを作成する可能性のあるパスには `ObjectLens` を使用する。
- パッケージのポインタ表現を `@json.JsonPath` から独立させる。
- 単一のLensからは `LensError` を発生させ、集約チェックからは非ジェネリックな `Validation` を返す。
- 欠落プロパティと明示的なJSON `null` を異なる状態として保持する。
- すべての静的結果型を `Lens[T]` に保持し、バリデーションは成功または蓄積された問題のみを報告する。
- 異種バリデーションチェックを構成する際は `Lens::check` でLensの結果型を明示的に消去する。
- オブジェクトプロパティとプリミティブデコーダから開始する。
- 数値のパースと変換はMoonBitコアAPIに委譲し、パッケージ固有の数値パーサを保守しない。
- オプショナリティ、配列、リファインメント、変換、代替は基盤が安定した後にのみ追加する。
- 不透明なデコーダクロージャからのJSON SchemaやOpenAPI生成は約束しない。
- `set` および `modify` は、明示的な書き込みポリシーとLens則テストを伴う後のマイルストーンに予約する。
- バリデーションAPIに値の構築、型推論、または変更操作を追加しない。

## 問題提起

MoonBitの標準 `Json` 型はJSON値を表現し、その `FromJson` トレイトは完全な値をMoonBit型にデコードします。このパッケージは異なるユースケース、すなわち1つのJSONドキュメントから既知の位置を繰り返し選択し、選択された各値をデコードし、オプションですべての独立した失敗を1つのバリデーション結果に収集することを扱います。

コアモデルは以下の通りです：

```text
Lens[T]
├── location: Pointer
└── value interpretation: Decoder[T]
```

最初のリリースは、意図的に汎用的なJSONクエリ言語、完全なHaskell Lens実装、または `FromJson` 派生の置き換えではありません。将来のJSON Lensの読み取り側を確立しつつ、変異を初期スコープから除外します。

## 元の提案を変更するレビュー所見

### `Lens` を公開抽象化として維持する

従来のLensは読み取りとlawfulな更新の両方をサポートします。最初のマイルストーンは読み取りとデコードのみを実装しますが、将来の `set` および `modify` 操作は意図された設計空間の一部です。

したがって、パッケージと公開型は `lens` および `Lens[T]` を使用する必要があります。ドキュメントでは、どの操作が現在利用可能かを明確に記載し、名前が変異がすでに存在することを暗示しないようにする必要があります。

### ポインタ表現を所有する

現在の `@json.JsonPath` インターフェースは抽象的な `JsonPath` 型と追加メソッドを公開していますが、公開ルートコンストラクタは公開していません。主に `FromJson` および `JsonDecodeError` 向けに設計されています。

したがって、パッケージは独自の不透明な `Pointer` 型を必要とします。RFC 6901 JSON Pointerとしてレンダリングし、安全な構築および検査操作のみを公開する必要があります。`@json.JsonPath` に依存すると、パッケージがルートパスを構築できなくなり、公開エラーモデルがコア内部に結合されてしまいます。

### トラバーサルが失敗した位置を報告する

ルックアップは、要求されたポインタと正常にトラバースされたプレフィックスの両方を追跡する必要があります。

`/user/profile/name` のリクエストの場合：

- `name` が存在しない場合、`/user/profile/name` を報告する。
- `profile` が文字列の場合、`/user/profile` での型不一致を報告する。
- `user` が存在しない場合、`/user` を報告する。

すべての失敗に対して完全な要求ポインタを報告すると、中間の型エラーを誤って識別することになります。

### 発生したエラーとバリデーションデータを分離する

`Lens::get` は `Result` を返すのではなく、パッケージ固有の `LensError` を発生させる必要があります。エラーは1つの `Issue` を保持し、これはプレーンな構造化値のままであるため、集約バリデーションは例外を収集手段として使用せずに多くの問題を保持できます。

この分離により、各型は1つの役割を持ちます：

- `LensError` は、`raise` および `catch` で使用される型付き制御フローの境界です。
- `Issue` は、ポインタ、安定コード、およびオプションのメッセージを含む検査可能な診断データです。

公開パッケージAPIには `CustomError` という名前は汎用的すぎます。`LensError(Issue)` は、所有する抽象化と再利用可能な診断ペイロードの両方を識別します。

### Lensに静的型を保持する

MoonBitは、TypeScriptライブラリがZodスキーマ式から型を推論できるように、実行時のバリデーション定義のコレクションからコンパイル時の結果型を導出することはできません。バリデーションAPIは、`Schema[T]`、固定アリティビルダー、または値を生成するバリデーション結果でそのモデルを模倣してはいけません。

`Lens[T]` は静的型情報のソースです。集約バリデーションは各結果型を `Check` に明示的に消去し、すべてのチェックを評価し、成功または蓄積された問題のみを返します。バリデーション成功後、呼び出し側は元の型付きLensを通じて値の読み取りを続けます。

これは意図的に、バリデーション後にアクセスするとトラバーサルとデコードが再度実行されることを意味します。その重複を避けるには、異種型付きキャッシュまたは生成されたアプリケーション固有コードが必要であり、どちらも初期パッケージには属しません。

### 数値変換をMoonBitコアに委譲する

パッケージはJSONトラバーサル、型選択、構造化エラーマッピングを所有すべきですが、10進数、指数、符号、オーバーフロー、丸めアルゴリズムを所有すべきではありません。

`Json::Number` には、MoonBitコアがすでに生成する `Double` 値を使用します。保持されたソーステキストを再パースしないでください。その値を `Double::to_int` などの標準メソッドで変換し、標準の述語、範囲定数、逆変換を使用して結果を検証します。

後のデコーダが数値テキストを受け入れる場合、`@string.from_str`、`@string.parse_double`、または `@string.parse_int` などの現在の標準エントリポイントにパースを委譲し、発生した標準エラーを `DecodeProblem` に変換します。`@strconv.parse_*` は互換性のため残っていますが、対象ツールチェーンではdeprecatedです。新しいパッケージコードでは後継の `@string` APIを使用します。

手書きで数字を走査するループ、数値文法を複製する正規表現、パッケージ固有の10進数または指数パーサは対象外です。これにより、標準ライブラリのセマンティクスとメンテナンスの重複を回避します。

### オプショナリティを公開する前に存在セマンティクスを設計する

欠落と `null` は区別されます：

| 入力状態 | 必須文字列 | オプション文字列 | Nullable文字列 | オプションNullable文字列 |
|---|---:|---:|---:|---:|
| 欠落 | error | `None` | error | `None` |
| `null` | 型エラー | 型エラー | `None` | `None` |
| 文字列 | value | `Some(value)` | `Some(value)` | `Some(value)` |

オプションNullable値を `lens.optional().nullable()` として実装しないでください。どちらの操作も出力をオプションに変更するため、単純な連鎖はネストされたオプション型や曖昧なセマンティクスを生成します。3つの明示的なコンビネータを使用します：

```moonbit
lens.optional()
lens.nullable()
lens.optional_nullable()
```

これらの操作は、正確なMoonBitシグネチャがコンパイルおよびテストされるまで延期されます。

### 値の代替と位置のフォールバックを分離する

`or` 操作は曖昧です。以下のいずれかを意味する可能性があります：

- 同じ選択されたJSON値に対して別のデコーダを試す。
- 最初のLensが失敗した場合に別の位置を試す。

設計では別々の名前を使用する必要があります：

```text
Decoder::one_of2     alternatives for one value
Lens::or_else        fallback to another location, if this feature is needed
```

値の代替のみが初期バリデーションロードマップに属します。

### 未知フィールドのバリデーションにはオブジェクトメタデータが必要

独立した `Check` クロージャのみから構成されるバリデータは、オブジェクトの許可されるプロパティの完全なセットを知りません。その結果、未知フィールドの拒否を初期集約バリデータの単純なオプションとして正しく追加することはできません。

未知フィールドのバリデーションは、オブジェクト境界と宣言されたキーを記録する明示的なオブジェクトチェック表現を待つ必要があります。`strip_unknown` と `passthrough` はデータを変換または返すため、バリデーションのみのAPIには属しません。

### スキーマ生成には宣言的デコーダメタデータが必要

不透明な述語および変換クロージャは、JSON SchemaやOpenAPIに確実に変換できません。ポインタとデコーダの分離は実装構造を改善しますが、スキーマ生成には十分ではありません。

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

文字列表現はRFC 6901に従います：

- ルートは空文字列としてレンダリングされる。
- キーは `/key` を追加する。
- `~` は `~0` としてエスケープされる。
- `/` は `~1` としてエスケープされる。
- 配列インデックスはその10進表現を追加する。

### Decoder

`Decoder[T]` はすでに選択された1つのJSON値を解釈します。ドキュメントトラバーサルは実行しません。

```moonbit
pub struct Decoder[T] {
  priv decode_ : (Json) -> T raise DecodeProblem
}
```

`DecodeProblem` はパスに依存しない失敗情報を含むパッケージプライベートなサブエラーです。`Lens::get` はそれをキャッチし、選択されたポインタをアタッチして公開 `Issue` を生成し、`LensError(issue)` を発生させます。

プリミティブデコーダはJSONバリアントディスパッチを直接実行し、パッケージが安定した構造化エラーコードを提供できるようにする必要があります。これらのデコーダ内の数値パースと変換はMoonBitコアに委譲する必要があります。後の `Decoder::from_json[T : FromJson]` ブリッジは `JsonDecodeError` をキャッチするかもしれませんが、コアの人間可読メッセージは安定した構造化エラーコードではないため、失敗を外部デコード失敗として分類する必要があります。

### オブジェクトLens

`ObjectLens` は、子プロパティが宣言される可能性のある位置を表します。

```moonbit
pub struct ObjectLens {
  priv pointer : Pointer
}
```

これにより、`Lens[String]` から子文字列プロパティを作成するなどの無効なAPIを防ぎます。

### 型付きLens

```moonbit
pub struct Lens[T] {
  priv pointer : Pointer
  priv decoder : Decoder[T]
}
```

`Lens::get` は2つの操作を実行します：

1. ドキュメントをLensのポインタまでトラバースする。
2. 選択された値をそのデコーダでデコードする。

トラバーサルおよびデコードの失敗は、同じ公開 `Issue` 値に正規化され、`LensError` として発生します。

## フェーズ1公開API

実装中に正確な宣言構文を確認する必要がありますが、意図されたAPIサーフェスは以下の通りです：

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

フェーズ1ではキーセグメントのみを構築しますが、内部の失敗位置ルールはすでにテストでカバーされている必要があります。

## エラーモデル

エラーは構造化データであり、事前フォーマットされた文字列ではありません。

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
  InvalidInteger
  NumberOutOfRange(
    target~ : String,
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

最終的な可視性モードは狭められる可能性がありますが、消費者はテキストをパースせずにポインタとコードを検査できなければなりません。

`message` フィールドはオプションの診断コンテキストです。プログラムロジックは `message` ではなく `IssueCode` で分岐する必要があります。

ポインタはすでに欠落プロパティを識別するため、エラーに冗長なプロパティ名フィールドは必要ありません。

`Issue` 自体はサブエラーではありません。`LensError` のペイロードとして保持することで、`Validation::Invalid` は `Array[Issue]` を直接格納でき、`Lens::get` の呼び出し側は依然としてMoonBitの型付きエラー伝搬を使用できます。

## プリミティブデコードセマンティクス

### String

`Json::String` のみを受け入れます。

### Boolean

`Json::True` および `Json::False` のみを受け入れます。

### Number

選択されたMoonBitターゲットで表現可能な `Json::Number` 値のみを受け入れます。

フェーズ1の `number` デコーダは、`Json::Number` がすでに格納している `Double` を返します。保持されたテキスト表現を検査または再パースしません。標準の `Double::is_nan` および `Double::is_inf` 述語を使用して、非有限の結果を `NumberOutOfRange` で拒否します。

### 整数

JSONには数値型があり、独立した整数型はありません。`int` デコーダは `Json::Number` がすでに格納している `Double` から開始し、標準変換を使用します：

1. `Double::is_nan()` および `Double::is_inf()` を拒否する。
2. `@int.MIN_VALUE.to_double()` および `@int.MAX_VALUE.to_double()` と比較して範囲外の値を分類する。
3. `Double::to_int()` で変換する。
4. 結果の `Int` を `Int::to_double()` で戻し、元の値との一致を確認する。不一致であれば、小数部を持つ値など正確に変換できない入力として扱う。

このシーケンスは、MoonBitの標準的な飽和、切り捨て、および表現動作に依存しつつ、パッケージの `InvalidInteger` および `NumberOutOfRange` 分類を保持します。パッケージはJSON数値テキスト自体をパースしてはいけません。

### Raw JSON

`json` デコーダは常に選択された値で成功します。

## 1つのLensが `LensError` を発生させる理由

MoonBitはパッケージ定義のサブエラーに型付きの `raise` および `catch` 動作を提供します。`Lens::get` はそのネイティブ制御フローを使用するため、通常の読み取りは、呼び出し側に `Result` のラップ解除を強制せずに1つの失敗を伝搬します。

集約バリデーションは値ベースのままです。`validate` は各チェックに対して独立して `LensError(issue)` をキャッチし、含まれる `Issue` を保持し、収集されたすべての問題を `Validation::Invalid` で返します。1つのチェックの失敗が他の独立したチェックの評価を妨げてはいけません。

## フェーズ2集約バリデーション

### Validation

```moonbit
pub(all) enum Validation {
  Valid
  Invalid(Array[Issue])
}
```

`Invalid` は常に少なくとも1つの問題を含む必要があります。実装はプライベートな構築ヘルパーを通じてこの不変条件を強制する必要があります。専用の非空コレクション型はオプションであり、パッケージの残りの部分を改善しない限り、この不変条件のみのために導入すべきではありません。

`Valid` はデコードされた値を保持しません。バリデーションは、その呼び出しに対してすべての提供されたチェックが成功したことのみを確立します。

```moonbit
pub struct Check {
  priv run_ : (Json) -> Unit raise LensError
}

pub fn Lens::check[T](Self[T]) -> Check

pub fn validate(
  Json,
  Array[Check],
) -> Validation
```

`Check` は意図的な型消去の境界です。Lensのトラバーサルとデコーダを実行し、成功した値を破棄し、発生した `Issue` を集約用に保持します。

```moonbit
let user = object("user")
let name_lens = user.string("name")
let age_lens = user.int("age")

match validate(document, [name_lens.check(), age_lens.check()]) {
  Valid => {
    let name : String = name_lens.get(document)
    let age : Int = age_lens.get(document)
    consume(name, age)
  }
  Invalid(issues) => report(issues)
}
```

バリデータはチェックを配列順に評価し、同じ決定論的順序で問題を返します。MoonBitの構造体、タプル、列挙型、またはその他のアプリケーション値を構築することは決してありません。

## 後のコンビネータ

### リファインメント

リファインメントはデコードされた型を保持し、値の制約を追加します：

```text
Decoder[T] + (T -> Bool) -> Decoder[T]
```

公開APIは安定した制約コードを要求し、診断メッセージを受け入れてもよいです。

### 変換

変換はデコードされた型を変更します：

```text
Decoder[A] + (A -> B raise DecodeProblem) -> Decoder[B]
```

変換は `Decoder` に属し、使用感を実質的に改善する場合にのみ `Lens` に forwarding 便宜メソッドを追加します。

### 配列

配列サポートには以下が必要です：

- `Array[T]` 用のデコーダ。
- インデックスを含むアイテムレベルのポインタ。
- 最小、最大、および非空制約。
- フェイルファストなアイテムデコードと全アイテム問題の蓄積の間の明確な選択。

推奨されるデフォルトは、パッケージがすでにバリデーションユースケースを対象としているため、インデックス順にすべての独立したアイテム問題を蓄積することです。

### 値の代替

`Decoder::one_of2` は同じ選択された値に複数のデコーダを適用します。すべての代替が失敗した場合、失敗を区別できないリストに平坦化するのではなく、代替ごとにグループ化して保持します。

異なる出力型は、組み合わせの前に明示的なMoonBit列挙型にマッピングする必要があります。

### 判別共用体

判別共用体デコーダは、その判別子を1回デコードし、1つの同種 `Case[T]` を選択する必要があります。すべてのケースは同じ出力型（通常はアプリケーション列挙型）を生成する必要があり、結果の `Lens[T]` は静的に型付けされたままになります。

この機能は型付きLensデコードに属し、集約バリデーションには属しません。ケース選択には明示的なオブジェクト境界が必要なため、通常のオブジェクトLensが存在した後に設計する必要があります。

### 未知フィールド

未知フィールドの拒否は将来の宣言的オブジェクトチェックに属します：

| ポリシー | 動作 |
|---|---|
| `strict` | 宣言されていないキーを拒否する。 |

`strip_unknown` と `passthrough` は変換ポリシーであり、バリデーションポリシーではありません。これらが将来必要になった場合、明示的な変換出力を持つ別個のAPIが必要であり、`Validation` の意味を変更してはいけません。

## 変異は延期され、除外はされない

フェーズ1は `set` または `modify` を提供しません。

lawfulな変異が後で追加される可能性があるため、`Lens` という名前は保持されます。書き込みを公開する前に、設計は以下を解決する必要があります：

- 欠落している中間オブジェクトを作成するかどうか。
- 更新が永続的かインプレースか。
- 範囲外の配列インデックスがどのように動作するか。
- オプションLensおよびNullableLensが書き込みとどのように相互作用するか。

変異が実装された場合、`get`、`set`、および `modify` は同じ `Lens[T]` 抽象化に対する操作のままであるべきです。内部の書き込み実装は別個のソースファイルに存在してもよく、`Check` と `Validation` はバリデーション専用のままです。

すべての正常にトラバース可能なソースについて、テストは標準のLens則をカバーする必要があります：

```text
get(set(source, value)) = value
set(source, get(source)) = source
set(set(source, first), second) = set(source, second)
```

欠落または互換性のないパスに対する失敗動作はAPI契約の一部であり、これらの則が適用される前に指定する必要があります。

## 提供ロードマップ

### マイルストーン1: 選択基盤

- RFC 6901レンダリングを備えた不透明な `Pointer`。
- `JsonKind`、`IssueCode`、`Issue`、および `LensError`。
- 正確な失敗位置を備えたキーのみのルックアップ。
- `Decoder[T]`、`ObjectLens`、および `Lens[T]`。
- 文字列、ブール、数値、整数、および生JSONデコーダ。
- `Lens::get`。

終了基準：

- 公開例がコンパイルされる。
- プリミティブの成功および失敗動作がテストされる。
- すべてのトラバーサル失敗が正確な失敗ポインタを報告する。
- 小数および範囲外の整数ケースがカバーされる。
- 数値テストは、パッケージ固有のパーサではなく、委譲された標準変換の境界をテストする。

### マイルストーン2: 集約バリデーション

- 非ジェネリックな `Validation`。
- 型消去された `Check`。
- `Lens::check` および集約 `validate`。
- 決定論的エラー順序。
- 安定した制約コードを備えたリファインメント。

終了基準：

- すべてのチェックがバリデーション呼び出しごとに1回評価される。
- 複数の独立したフィールド問題が一緒に返される。
- 成功したバリデーションは、型付き値を構築またはキャッシュせずに `Valid` を返す。
- 呼び出し側は、元の `Lens[T]` 値を介して正常にバリデーションされたデータに引き続きアクセスする。

### マイルストーン3: 存在とコレクション

- `optional`、`nullable`、および `optional_nullable`。
- デフォルトでは欠落値にのみ適用される `default`。
- インデックス付きポインタを備えた配列アイテムデコード。
- 配列長制約。
- 変換。

終了基準：

- 欠落/nullの真理値表がカバーされる。
- 配列問題の順序が決定論的である。
- デフォルトが明示的な `null` や無効な存在値を隠すことがない。

### マイルストーン4: 代替とオブジェクトチェック

- `Decoder::one_ofN`。
- 判別共用体。
- 宣言的オブジェクト境界。
- 未知フィールドの拒否。

JSON SchemaおよびOpenAPIの生成は、サポートされるすべての制約に宣言的メタデータを必要とする別個の提案のままです。

### 将来のマイルストーン: Lawfulな変異

- `Lens::set`。
- `Lens::modify`。
- 明示的な欠落パス、互換性のないパス、および配列インデックス書き込みポリシー。
- 永続的更新とインプレース更新の間の文書化された選択。
- すべての書き込み可能なLensカテゴリに対するLens則テスト。

このマイルストーンは、実際の呼び出し側が変異を必要とするまではオプションですが、公開の命名と内部ポインタモデルはそれを妨げてはいけません。

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

マイルストーン2で `check.mbt` と `validation.mbt` を追加します。オプショナリティ、配列、および代替のためのファイルは、それらの機能が実装されたときにのみ追加します。

## マイルストーン1のテストマトリックス

- ルートプロパティ成功。
- ネストされたプロパティ成功。
- 欠落したルートプロパティ。
- 欠落した中間プロパティ。
- 欠落したリーフプロパティ。
- キーLensに対する非オブジェクトルート。
- 非オブジェクト中間値。
- 文字列型不一致。
- ブール型不一致。
- 数値型不一致。
- 非有限または表現不可能な数値。
- `int` に渡された小数値。
- 正および負の `Int` オーバーフロー。
- 正確な `@int.MIN_VALUE` および `@int.MAX_VALUE` 変換。
- 安定した `IssueCode` 値にマッピングされた標準数値変換の失敗。
- すべてのプリミティブデコーダに渡された明示的な `null`。
- `~`、`/`、および空キーのJSON Pointerエスケープ。
- すべてのトラバーサルおよびデコード失敗に対する正しいポインタ。
- 複数のドキュメントに対して1つのLensを再利用。

## 延期された決定

以下の選択はマイルストーン1をブロックせず、実装の根拠をもって解決されるべきです：

- `Issue`、`IssueCode`、`JsonKind`、および `LensError` のペイロードを完全公開にするか読み取り専用にするか。
- `Pointer` がそのセグメントを公開するか、反復と文字列変換のみを公開するか。
- 配列アイテムバリデーションがデフォルトで失敗を蓄積するか、蓄積モードとフェイルファストモードの両方を公開するか。
- `FromJson` ブリッジが、そのあまり構造化されていないエラー分類にもかかわらず、十分に有用かどうか。
- 将来の書き込みが永続的更新とインプレース更新のどちらを使用するか。
- 欠落している中間オブジェクトがエラーか、明示的な書き込みポリシーによって作成可能か。
- オプションLensおよびNullableLensが、欠落または `null` 値を対象とした書き込み時にどのように動作するか。

## 参考文献

- [MoonBitメソッドおよびトレイトドキュメント](https://docs.moonbitlang.com/en/stable/language/methods.html)
- [MoonBitエラーハンドリングドキュメント](https://docs.moonbitlang.com/en/stable/language/error-handling.html)
- [MoonBit導出ドキュメント](https://docs.moonbitlang.com/en/stable/language/derive.html)
- [MoonBitコアJSON API](https://mooncakes.io/docs/moonbitlang/core/json)
- [MoonBitコア文字列パースAPI](https://mooncakes.io/docs/moonbitlang/core/string)
- [MoonBit `Double::to_int` 実装およびセマンティクス](https://mooncakes.io/assets/moonbitlang/core/builtin/double_to_int_wasm.mbt.html)
- [MoonBitコアAPIインデックス](https://mooncakes.io/docs/moonbitlang/core/)
- [RFC 6901: JSON Pointer](https://www.rfc-editor.org/rfc/rfc6901)
