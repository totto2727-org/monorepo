# Typed JSON Lens and Validation for MoonBit

## 状況

本ドキュメントは、将来の `lens` パッケージに向けてレビュー済みの設計方針です。

提案は、以下に記録された修正を経た後に実現可能です。その主要な公開抽象化は `Lens[T]` です。最初のリリースでは読み取り側のみを公開し、名称は将来の lawful な `set` および `modify` API を意図的に予約しています。

このレビューは MoonBit 0.10.4 および `moonbitlang/core` 0.10.4 を対象としています。

## 決定の概要

- 読み取り専用の型付きJSONレンズとバリデーションライブラリから開始する。
- レンズを、パッケージが所有するJSON Pointerと値デコーダの組み合わせとしてモデル化する。
- 公開型付き抽象化には `Lens[T]` を、子プロパティのレンズを作成する可能性のあるパスには `ObjectLens` を使用する。
- パッケージのポインタ表現を `@json.JsonPath` から独立させて維持する。
- 単一のレンズからは `LensError` を発生させ、集約チェックからは非ジェネリックな `Validation` を返す。
- 欠損プロパティと明示的な JSON `null` を異なる状態として保持する。
- すべての静的結果型は `Lens[T]` に保持し、バリデーションは成功または蓄積された問題のみを報告する。
- 異種のバリデーションチェックを構成する際には、`Lens::check` を使用してレンズの結果型を明示的に消去する。
- オブジェクトプロパティとプリミティブデコーダから開始する。
- 数値のパースと変換は MoonBit コアAPIに委譲し、パッケージ固有の数値パーサを維持しない。
- オプショナリティ、配列、リファインメント、変換、代替は基盤が安定してから追加する。
- 不透明なデコーダクロージャからのJSON SchemaやOpenAPI生成は約束しない。
- `set` と `modify` は、明示的な書き込みポリシーとレンズ則テストを伴う将来のマイルストーンに予約する。
- バリデーションAPIに値の構築、型推論、またはミューテーション操作を追加しない。

## 問題の定義

MoonBit の標準 `Json` 型は JSON 値を表現し、その `FromJson` トレイトは完全な値を MoonBit の型にデコードします。このパッケージは別のユースケースに対処します。すなわち、1つのJSONドキュメントから既知の位置を繰り返し選択し、選択された各値をデコードし、オプションで全ての独立した失敗を1つのバリデーション結果に集約することです。

コアモデルは次のとおりです：

```text
Lens[T]
├── location: Pointer
└── value interpretation: Decoder[T]
```

最初のリリースは、意図的に汎用的なJSONクエリ言語でも、完全なHaskellレンズ実装でも、`FromJson` の導出を置き換えるものでもありません。将来のJSONレンズの読み取り側を確立しつつ、ミューテーションを初期スコープから除外します。

## 元の提案を変更するレビュー所見

### 公開抽象化として `Lens` を維持する

従来のレンズは読み取りと lawful な更新の両方をサポートします。最初のマイルストーンでは読み取りとデコードのみを実装しますが、将来の `set` および `modify` 操作は設計スペースの一部です。

したがって、パッケージと公開型は `lens` および `Lens[T]` を使用する必要があります。ドキュメントでは、どの操作が現在利用可能かを明確に記載し、名称がミューテーションが既に存在することを暗示しないようにしなければなりません。

### ポインタ表現を所有する

現在の `@json.JsonPath` インターフェースは抽象 `JsonPath` 型と追加メソッドを公開していますが、公開のルートコンストラクタは公開していません。主に `FromJson` と `JsonDecodeError` のために設計されています。

したがって、パッケージは独自の不透明な `Pointer` 型を必要とします。これはRFC 6901 JSON Pointerとしてレンダリングされ、安全な構築および検査操作のみを公開する必要があります。`@json.JsonPath` に依存すると、パッケージがルートパスを構築できなくなり、公開エラーモデルがコア内部と結合してしまいます。

### トラバーサルに失敗した位置を報告する

ルックアップは、要求されたポインタと正常にトラバースされたプレフィックスの両方を追跡する必要があります。

`/user/profile/name` への要求の場合：

- `name` が欠損している場合、`/user/profile/name` を報告する。
- `profile` が文字列の場合、`/user/profile` での型不一致を報告する。
- `user` が欠損している場合、`/user` を報告する。

すべての失敗に対して要求された完全なポインタを報告すると、中間の型エラーを誤って識別することになります。

### 発生したエラーとバリデーションデータを分離する

`Lens::get` は `Result` を返すのではなく、パッケージ固有の `LensError` を発生させる必要があります。エラーは1つの `Issue` を保持します。`Issue` はプレーンな構造化値のままであり、集約バリデーションが例外を収集手段として使用せずに多くの問題を保持できるようにします。

この分離により、各型は1つの役割を持ちます：

- `LensError` は `raise` および `catch` で使用される型付き制御フロー境界です。
- `Issue` は、ポインタ、安定したコード、およびオプションのメッセージを含む、検査可能な診断データです。

公開パッケージAPIには `CustomError` という名前は汎用的すぎます。`LensError(Issue)` は、所有する抽象化と再利用可能な診断ペイロードの両方を識別します。

### 静的型はレンズに保持する

MoonBit は、TypeScriptライブラリがZodスキーマ式から型を推論できるように、実行時のバリデーション定義のコレクションからコンパイル時の結果型を導出できません。バリデーションAPIは、`Schema[T]`、固定アリティのビルダー、または値を生成するバリデーション結果でそのモデルを模倣してはいけません。

`Lens[T]` は静的型情報のソースです。集約バリデーションは各結果型を明示的に `Check` に消去し、すべてのチェックを評価し、成功または蓄積された問題のみを返します。バリデーション成功後、呼び出し元は元の型付きレンズを通じて値を読み取り続けます。

これは意図的に、バリデーション後のアクセスがトラバーサルとデコードを再度実行することを意味します。その重複を避けるには、異種型付きキャッシュまたはアプリケーション固有の生成コードが必要であり、どちらも初期パッケージには属しません。

### 数値変換は MoonBit コアに委譲する

パッケージはJSONのトラバーサル、型選択、構造化エラーマッピングを所有するべきですが、小数、指数、符号、オーバーフロー、丸めのアルゴリズムを所有するべきではありません。

`Json::Number` には、MoonBitコアが既に生成する `Double` 値を使用します。保持されているソーステキストを再パースしてはいけません。`Int` が要求された場合は、`Double::to_int()` に直接委譲し、パッケージレベルでのバリデーションなしにその標準的な変換動作を継承します。

将来のデコーダが数値テキストを受け入れる場合、パースは現在の非推奨ではない標準エントリポイント（`@string.from_str`、`@string.parse_double`、`@string.parse_int` など）に委譲し、発生した標準エラーを `DecodeProblem` に変換します。レビュー対象のツールチェーンは依然として `@strconv.parse_*` を非推奨の互換性APIとして公開しています。新しいパッケージコードはサポートされている `@string` の代替を使用するべきです。

手書きの数字ループ、数値文法を複製する正規表現、およびパッケージ固有の小数または指数パーサはスコープ外です。これにより、標準ライブラリのセマンティクスとメンテナンスの重複を回避します。

### オプショナリティを公開する前に存在セマンティクスを設計する

欠損と `null` は異なります：

| 入力状態 | 必須文字列 | オプション文字列 | null許容文字列 | オプションnull許容文字列 |
|---|---:|---:|---:|---:|
| Missing | error | `None` | error | `None` |
| `null` | type error | type error | `None` | `None` |
| String | value | `Some(value)` | `Some(value)` | `Some(value)` |

オプションのnull許容値を `lens.optional().nullable()` として実装しないでください。どちらの操作も出力をオプションに変更するため、単純な連鎖はネストされたオプション型または曖昧なセマンティクスを生成します。3つの明示的なコンビネータを使用します：

```moonbit
lens.optional()
lens.nullable()
lens.optional_nullable()
```

これらの操作は、正確な MoonBit シグネチャがコンパイルおよびテストされるまで延期されます。

### 値の代替と位置のフォールバックを分離する

`or` 操作は曖昧です。次のいずれかを意味する可能性があります：

- 同じ選択されたJSON値に対して別のデコーダを試す。
- 最初のレンズが失敗した場合に別の位置を試す。

設計では別々の名前を使用する必要があります：

```text
Decoder::one_of2     1つの値に対する代替
Lens::or_else        別の位置へのフォールバック（この機能が必要な場合）
```

初期のバリデーションロードマップに属するのは値の代替のみです。

### 未知フィールドのバリデーションにはオブジェクトメタデータが必要

独立した `Check` クロージャのみから構成されるバリデータは、オブジェクトの許可されたプロパティの完全なセットを認識しません。その結果、未知フィールドの拒否を初期の集約バリデータの単純なオプションとして正しく追加することはできません。

未知フィールドのバリデーションは、オブジェクトの境界と宣言されたキーを記録する明示的なオブジェクトチェック表現を待つ必要があります。`strip_unknown` と `passthrough` はデータを変換または返すため、バリデーション専用のAPIには属しません。

### スキーマ生成には宣言的デコーダメタデータが必要

不透明な述語クロージャと変換クロージャは、JSON SchemaやOpenAPIに確実に変換できません。ポインタとデコーダの分離は実装構造を改善しますが、スキーマ生成には十分ではありません。

スキーマ生成は、将来の設計で宣言的制約モデルが導入されない限り、非目標です。

## アーキテクチャ

### Pointer

`Pointer` は不透明なパッケージ型です。内部的に順序付きパスセグメントを格納します。

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

`Decoder[T]` は、既に選択された1つのJSON値を解釈します。ドキュメントのトラバーサルは実行しません。

```moonbit
pub struct Decoder[T] {
  priv decode_ : (Json) -> T raise DecodeProblem
}
```

`DecodeProblem` はパッケージ非公開のサブエラーで、パスに依存しない失敗情報を含みます。`Lens::get` はそれをキャッチし、選択されたポインタをアタッチして公開の `Issue` を生成し、`LensError(issue)` を発生させます。

プリミティブデコーダはJSONバリアントディスパッチを直接実行する必要があります。これにより、パッケージは安定した構造化エラーコードを提供できます。それらのデコーダ内部での数値パースと変換は MoonBit コアに委譲しなければなりません。将来の `Decoder::from_json[T : FromJson]` ブリッジは `JsonDecodeError` をキャッチするかもしれませんが、コアの人間可読なメッセージは安定した構造化エラーコードではないため、その失敗は外部デコード失敗として分類するべきです。

### オブジェクトレンズ

`ObjectLens` は、子プロパティが宣言され得る位置を表します。

```moonbit
pub struct ObjectLens {
  priv pointer : Pointer
}
```

これにより、`Lens[String]` から子文字列プロパティを作成するなどの無効なAPIを防ぎます。

### 型付きレンズ

```moonbit
pub struct Lens[T] {
  priv pointer : Pointer
  priv decoder : Decoder[T]
}
```

`Lens::get` は2つの操作を実行します：

1. レンズのポインタまでドキュメントをトラバースする。
2. 選択された値をデコーダでデコードする。

トラバーサルとデコードの失敗は、同じ公開 `Issue` 値に正規化され、`LensError` として発生します。

## フェーズ1の公開API

実装中に正確な宣言構文を確認する必要がありますが、意図するAPIサーフェスは次のとおりです：

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

使用例：

```moonbit
fn read_name(document : Json) -> String raise LensError {
  object("user").object("profile").string("name").get(document)
}

let name : String = read_name(document)
```

## ルックアップセマンティクス

ルックアップはルートから開始し、各セグメントが成功した後にトラバースされたポインタを記録します。

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

最終的な可視性モードは狭められる可能性がありますが、コンシューマはテキストをパースせずにポインタとコードを検査できなければなりません。

`message` フィールドはオプションの診断コンテキストです。プログラムロジックは `IssueCode` で分岐すべきであり、`message` では分岐すべきではありません。

ポインタは既に欠損プロパティを識別するため、エラーに冗長なプロパティ名フィールドは必要ありません。

`Issue` 自体はサブエラーではありません。`LensError` のペイロードとして保持することで、`Validation::Invalid` は `Array[Issue]` を直接格納できる一方、`Lens::get` の呼び出し元は MoonBit の型付きエラー伝搬を引き続き使用できます。

## プリミティブデコードセマンティクス

### String

`Json::String` のみを受け入れます。

### Boolean

`Json::True` および `Json::False` のみを受け入れます。

### Number

`Json::Number` のみを受け入れます。

フェーズ1の `number` デコーダは、有限性や範囲のバリデーションなしに、`Json::Number` が既に格納している `Double` を返します。保持されているテキスト表現を検査したり再パースしたりしません。

### Integer

JSONには数値型があり、独立した整数型はありません。`int` デコーダは、`Json::Number` が既に格納している `Double` に `Double::to_int()` を直接適用します。有限性、範囲、整数厳密性のバリデーションは実行しないため、MoonBit の標準的な切り捨て、飽和、特殊値の動作を継承します。パッケージはJSONの数値テキスト自体をパースしてはいけません。

### Raw JSON

`json` デコーダは常に選択された値で成功します。

## 単一レンズが `LensError` を発生させる理由

MoonBit はパッケージ定義のサブエラーに型付きの `raise` および `catch` 動作を提供します。`Lens::get` はそのネイティブ制御フローを使用するため、通常の読み取りは呼び出し元に `Result` のアンラップを強制せずに1つの失敗を伝搬します。

集約バリデーションは値ベースのままです。`validate` は各チェックに対して独立して `LensError(issue)` をキャッチし、含まれている `Issue` を保持し、収集されたすべての問題を `Validation::Invalid` で返します。1つのチェックの失敗は、他の独立したチェックの評価を妨げてはいけません。

## フェーズ2：集約バリデーション

### Validation

```moonbit
pub enum Validation {
  Valid
  Invalid(Array[Issue])
}
```

`Invalid` は常に少なくとも1つの問題を含まなければなりません。実装はプライベートな構築ヘルパーを通じてこの不変条件を強制するべきです。専用の非空コレクション型はオプションであり、パッケージの残りの部分を改善しない限り、この不変条件のみのために導入すべきではありません。

`Validation` はパッケージ外部では読み取り専用です。コンシューマはパターンマッチングを通じてそれを分解できますが、`Valid` または `Invalid` を構築できるのはこのパッケージのみであり、`Invalid([])` の外部構築を防ぎます。

`Valid` はデコードされた値を保持しません。バリデーションは、その呼び出しに対して提供されたすべてのチェックが成功したことのみを確立します。

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

`Check` は意図的な型消去境界です。レンズのトラバーサルとデコーダを実行し、成功した値を破棄し、発生した `Issue` を集約のために保持します。

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

バリデータは配列の順序でチェックを評価し、同じ決定論的な順序で問題を返します。MoonBitの構造体、タプル、列挙型、またはその他のアプリケーション値を構築することは決してありません。

## 将来のコンビネータ

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

変換は `Decoder` に属し、使用を実質的に改善する場合にのみ `Lens` 上の転送便利メソッドとして提供します。

### 配列

配列サポートには以下が必要です：

- `Array[T]` 用のデコーダ。
- インデックスを含むアイテムレベルのポインタ。
- 最小、最大、および非空の制約。
- フェイルファストなアイテムデコードと全アイテムの問題の蓄積の間の明確な選択。

推奨されるデフォルトは、インデックス順にすべての独立したアイテム問題を蓄積することです。これはパッケージが既にバリデーションユースケースを対象としているためです。

### 値の代替

`Decoder::one_of2` は、同じ選択された値に複数のデコーダを適用します。すべての代替が失敗した場合、失敗を代替ごとにグループ化して保持し、判別不能なリストに平坦化しないでください。

異なる出力型は、組み合わせの前に明示的な MoonBit 列挙型にマッピングする必要があります。

### 判別共用体

判別共用体デコーダは、弁別子を1回デコードし、1つの均質な `Case[T]` を選択する必要があります。すべてのケースは同じ出力型（通常はアプリケーションの列挙型）を生成する必要があるため、結果として得られる `Lens[T]` は静的に型付けされたままになります。

この機能は型付きレンズデコードに属し、集約バリデーションには属しません。通常のオブジェクトレンズが存在した後に設計されるべきです。なぜなら、ケース選択には明示的なオブジェクト境界が必要だからです。

### 未知フィールド

未知フィールドの拒否は、将来の宣言的オブジェクトチェックに属します：

| ポリシー | 動作 |
|---|---|
| `strict` | 宣言されていないキーを拒否する。 |

`strip_unknown` と `passthrough` は変換ポリシーであり、バリデーションポリシーではありません。それらが将来必要になった場合、明示的な変換出力を持つ別のAPIが必要であり、`Validation` の意味を変更してはいけません。

## ミューテーションは延期され、除外されてはいない

フェーズ1は `set` または `modify` を提供しません。

`Lens` という名前は、lawful なミューテーションが後で追加される可能性があるため維持されます。書き込みを公開する前に、設計は以下を解決しなければなりません：

- 欠損している中間オブジェクトを作成するかどうか。
- 更新が永続的かインプレースか。
- 範囲外の配列インデックスがどのように動作するか。
- オプショナルレンズとnull許容レンズが書き込みとどのように相互作用するか。

ミューテーションが実装される場合、`get`、`set`、`modify` は同じ `Lens[T]` 抽象化に対する操作として残るべきです。内部の書き込み実装は別のソースファイルに存在してもよく、`Check` と `Validation` はバリデーション専用のままです。

正常にトラバース可能なすべてのソースについて、テストは標準的なレンズ則をカバーするべきです：

```text
get(set(source, value)) = value
set(source, get(source)) = source
set(set(source, first), second) = set(source, second)
```

欠損または互換性のないパスの失敗動作はAPI契約の一部であり、これらの法則が適用される前に指定されなければなりません。

## 配信ロードマップ

### マイルストーン1：選択基盤

- RFC 6901レンダリングを使用した不透明な `Pointer`。
- `JsonKind`、`IssueCode`、`Issue`、および `LensError`。
- 正確な失敗位置を持つキーのみのルックアップ。
- `Decoder[T]`、`ObjectLens`、および `Lens[T]`。
- 文字列、真偽値、数値、整数、および生JSONデコーダ。
- `Lens::get`。

終了基準：

- 公開サンプルがコンパイルされる。
- プリミティブの成功と失敗の動作がテストされている。
- すべてのトラバーサル失敗が正確な失敗ポインタを報告する。
- 小数、範囲外、非有限の整数ケースが `Double::to_int()` セマンティクスに従う。
- 数値テストは、パッケージ固有のパーサではなく、委譲された標準変換の境界をテストする。

### マイルストーン2：集約バリデーション

- 非ジェネリックな `Validation`。
- 型消去された `Check`。
- `Lens::check` と集約 `validate`。
- 決定論的なエラー順序付け。
- 安定した制約コードを使用したリファインメント。

終了基準：

- すべてのチェックがバリデーション呼び出しごとに1回評価される。
- 複数の独立したフィールド問題が一緒に返される。
- 成功したバリデーションは、型付き値を構築またはキャッシュせずに `Valid` を返す。
- 呼び出し元は、元の `Lens[T]` 値を介して正常にバリデーションされたデータに引き続きアクセスする。

### マイルストーン3：存在とコレクション

- `optional`、`nullable`、および `optional_nullable`。
- `default`、デフォルトでは欠損値にのみ適用される。
- インデックス付きポインタを使用した配列アイテムデコード。
- 配列長制約。
- 変換。

終了基準：

- 欠損/nullの真理値表がカバーされている。
- 配列問題の順序が決定論的である。
- デフォルトが明示的な `null` や無効な現在値を隠すことは決してない。

### マイルストーン4：代替とオブジェクトチェック

- `Decoder::one_ofN`。
- 判別共用体。
- 宣言的オブジェクト境界。
- 未知フィールドの拒否。

JSON SchemaとOpenAPIの生成は、サポートされるすべての制約に宣言的メタデータを必要とする別個の提案のままです。

### 将来のマイルストーン：Lawful なミューテーション

- `Lens::set`。
- `Lens::modify`。
- 明示的な欠損パス、互換性のないパス、および配列インデックス書き込みポリシー。
- 永続的更新とインプレース更新の間の文書化された選択。
- 書き込み可能なすべてのレンズカテゴリに対するレンズ則テスト。

このマイルストーンは、実際の呼び出し元がミューテーションを必要とするまでオプションですが、公開の命名と内部ポインタモデルはそれを妨げないようにしなければなりません。

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

`check.mbt` と `validation.mbt` はマイルストーン2で追加します。オプショナリティ、配列、および代替のためのファイルは、それらの機能が実装されたときにのみ追加します。

## マイルストーン1のテストマトリックス

- ルートプロパティ成功。
- ネストされたプロパティ成功。
- 欠損ルートプロパティ。
- 欠損中間プロパティ。
- 欠損リーフプロパティ。
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
- `~`、`/`、および空キーのJSON Pointerエスケープ。
- すべてのトラバーサルおよびデコード失敗に対する正しいポインタ。
- 複数のドキュメントに対して1つのレンズを再利用する。

## 延期された決定

以下の選択肢はマイルストーン1をブロックせず、実装の証拠とともに解決されるべきです：

- `Issue`、`IssueCode`、`JsonKind`、および `LensError` のペイロードを完全公開にするか読み取り専用にするか。
- `Pointer` がそのセグメントを公開するか、イテレーションと文字列変換のみとするか。
- 配列アイテムバリデーションがデフォルトで失敗を蓄積するか、両方のモード（蓄積とフェイルファスト）を公開するか。
- `FromJson` ブリッジが、その構造化されていないエラー分類にもかかわらず、十分に有用かどうか。
- 将来の書き込みが永続的更新かインプレース更新を使用するか。
- 欠損中間オブジェクトがエラーか、明示的な書き込みポリシーによって作成される可能性があるか。
- オプショナルレンズとnull許容レンズが、欠損または `null` 値を対象とした書き込み時にどのように動作するか。

## 参考文献

- [MoonBit method and trait documentation](https://docs.moonbitlang.com/en/stable/language/methods.html)
- [MoonBit error handling documentation](https://docs.moonbitlang.com/en/stable/language/error-handling.html)
- [MoonBit deriving documentation](https://docs.moonbitlang.com/en/stable/language/derive.html)
- [MoonBit core JSON API](https://mooncakes.io/docs/moonbitlang/core/json)
- [MoonBit core string parsing API](https://mooncakes.io/docs/moonbitlang/core/string)
- [MoonBit `Double::to_int` implementation and semantics](https://mooncakes.io/assets/moonbitlang/core/builtin/double_to_int_wasm.mbt.html)
- [MoonBit core API index](https://mooncakes.io/docs/moonbitlang/core/)
- [RFC 6901: JSON Pointer](https://www.rfc-editor.org/rfc/rfc6901)