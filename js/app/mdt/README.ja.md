# mdt

[opencode SDK](https://opencode.ai/docs/sdk/)をエンジンとして使用し、単一のマークダウンファイルを翻訳するCLIです。既存のopencode認証とプロバイダー設定を再利用し、利用可能なすべてのツールを無効化することで、モデルは入力プロンプトの読み取りとテキスト出力のみを行えます。

## なぜこれが存在するのか

- すでにopencodeでプロバイダーと認証を設定済みであれば、`mdt`はその設定を借用するため、新しいAPIキーは必要ありません。
- 翻訳は単一ショットのテキストタスクです。opencodeが通常公開するエージェントハーネス、ファイルシステムアクセス、シェルツールはこのユースケースでは不要であり、リスクとなります。
- `mdt`はインプロセスのopencodeサーバーを起動し、`/experimental/tool/ids`経由ですべてのツールIDを取得し、プロンプト上でそれらをすべて無効化します。モデルは入力マークダウン以外の何も参照できません。

## インストール

このパッケージはワークスペースの一部です。リポジトリルートで一度インストールします：

```bash
pnpm install
vp run --filter @totto2727/mdt build
```

バイナリは `js/app/mdt/dist/bin.mjs` に出力されます。

## 使用方法

```bash
mdt <file> --lang <code> [--model <provider/model>] [--force]
```

| フラグ    | エイリアス | 説明                             | デフォルト                      |
| --------- | ---------- | -------------------------------- | ------------------------------- |
| `--lang`  | `-l`       | 対象言語コード（例：`ja`, `en`） | 必須                            |
| `--model` | `-m`       | `provider/model`形式のモデル指定 | `opencode-go/deepseek-v4-flash` |
| `--force` | `-f`       | 出力ファイルが既存の場合に上書き | オフ                            |

### 出力パスのルール

`mdt`は、拡張子の前に言語タグを挿入した同名ファイルを出力します。`.mbt.md`のような複合拡張子は保持されます。

| 入力              | `--lang ja` 出力                             |
| ----------------- | -------------------------------------------- |
| `hoge.md`         | `hoge.ja.md`                                 |
| `hoge.mbt.md`     | `hoge.ja.mbt.md`                             |
| `README.draft.md` | `README.draft.ja.md`                         |
| `hoge.en.md`      | `hoge.ja.md`（既存の言語タグは置換されます） |
| `hoge.en.mbt.md`  | `hoge.ja.mbt.md`                             |

既知の言語タグは `ja` と `en` です。既知の複合拡張子は `.mbt.md` です。どちらのリストも `src/lib/path.ts` にあります。

## 例

```bash
# デフォルトモデルで日本語に翻訳
mdt docs/intro.md --lang ja

# 特定のモデルで英語に翻訳
mdt docs/intro.ja.md --lang en --model anthropic/claude-sonnet-4-6

# 既存の翻訳を上書き
mdt docs/intro.md --lang ja --force
```

## エディター連携

カレントバッファに対してシェルコマンドを実行できる任意のエディターで `mdt` を利用できます。以下のZedの例は、バイナリが `PATH` 上にあることを前提としています。

`.zed/tasks.json`:

```json
[
  {
    "label": "mdt: translate to ja",
    "command": "mdt $ZED_FILE --lang ja"
  }
]
```

## 仕組み

1. `createOpencode()` が `opencode.json` と保存された認証情報を継承したインプロセスopencodeサーバーを起動します。
2. `client.tool.ids()` がすべてのビルトインツールおよびMCP登録ツールを列挙します。
3. `client.session.create()` が新しいセッションを開きます。
4. `client.session.prompt()` がファイル内容を送信します。このとき、すべてのツールIDに対して `tools: { [id]: false }` を設定し、翻訳済みマークダウンのみを出力するよう制約するシステムプロンプトも付与します。
5. `client.session.messages()` でアシスタントの応答を取得し、連結されたテキスト部分を解決された出力パスに書き込みます。
6. opencodeサーバーはEffectスコープが終了するときに閉じられます。

## 制限事項

- デフォルトモデル `opencode-go/deepseek-v4-flash` はopencode設定でプロバイダーとして設定されている必要があります。別のプロバイダーを使用する場合は `--model` で上書きしてください。
- `/experimental/tool/ids` エンドポイントは現在opencode APIの `experimental` 配下にあります。SDKが将来の移行に対応するはずですが、破損の可能性はあります。
- 大きなマークダウンファイルはモデルのコンテキストウィンドウを超過する可能性があります。チャンク分割は行われません。1回のプロンプトでファイル全体を翻訳します。
