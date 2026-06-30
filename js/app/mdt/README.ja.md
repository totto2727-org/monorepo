# mdt

`opencode SDK`（https://opencode.ai/docs/sdk/）をエンジンとして使用し、単一のマークダウンファイルを翻訳するCLIです。既存のopencode認証とプロバイダー設定を再利用し、利用可能なすべてのツールを無効化することで、モデルは入力プロンプトの読み取りとテキスト出力のみを行えます。

## 存在理由

- すでにopencodeでプロバイダーと認証を設定済み — `mdt` はその設定を借用するため、新しいAPIキーは不要です。
- 翻訳は単発のテキストタスクであり、opencodeが通常公開するエージェントハーネス、ファイルシステムアクセス、シェルツールはこのユースケースでは不要かつリスクがあります。
- `mdt` はインプロセスでopencodeサーバーを起動し、`/experimental/tool/ids` 経由ですべてのツールIDを取得し、プロンプト上でそれらをすべて無効化します。モデルは入力マークダウン以外の何も参照できません。

## インストール

このパッケージはワークスペースの一部です。リポジトリルートで一度インストールしてください：

```bash
bun install
vp run --filter @totto2727/mdt build
```

バイナリは `js/app/mdt/dist/bin.mjs` に生成されます。

## 使用方法

```bash
mdt <file> --lang <code> [--model <provider/model>] [--force]
```

| フラグ    | エイリアス | 説明                             | デフォルト                      |
| --------- | ---------- | -------------------------------- | ------------------------------- |
| `--lang`  | `-l`       | 対象言語コード（例：`ja`、`en`） | 必須                            |
| `--model` | `-m`       | `provider/model` 形式のモデル    | `opencode-go/deepseek-v4-flash` |
| `--force` | `-f`       | 出力ファイルが既存の場合に上書き | オフ                            |

### 出力パスのルール

`mdt` は拡張子の前に言語タグを挿入した兄弟ファイルに書き込みます。`.mbt.md` のような複合拡張子は保持されます。

| 入力              | `--lang ja` の出力                       |
| ----------------- | ---------------------------------------- |
| `hoge.md`         | `hoge.ja.md`                             |
| `hoge.mbt.md`     | `hoge.ja.mbt.md`                         |
| `README.draft.md` | `README.draft.ja.md`                     |
| `hoge.en.md`      | `hoge.ja.md`（既存の言語タグは置き換え） |
| `hoge.en.mbt.md`  | `hoge.ja.mbt.md`                         |

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

シェルコマンドを実行できるエディターは `mdt` を利用できます。以下のZedの例はバイナリが `PATH` 上にあることを前提としています。

`.zed/tasks.json`：

```json
[
  {
    "label": "mdt: translate to ja",
    "command": "mdt $ZED_FILE --lang ja"
  }
]
```

## 仕組み

1. `createOpencode()` が `opencode.json` と保存済み認証情報を継承したインプロセスのopencodeサーバーを起動します。
2. `client.tool.ids()` がすべてのビルトインツールとMCP登録ツールを列挙します。
3. `client.session.create()` が新しいセッションを開きます。
4. `client.session.prompt()` がファイル内容を送信します。その際、すべてのIDに対して `tools` を `{ [id]: false }` に設定し、翻訳後のマークダウンのみを出力するようモデルを制約するシステムプロンプトも付与します。
5. `client.session.messages()` がアシスタントの応答を取得し、連結されたテキスト部分が解決された出力パスに書き込まれます。
6. Effectスコープが終了するとopencodeサーバーが閉じられます。

## 制限事項

- デフォルトモデル `opencode-go/deepseek-v4-flash` はopencode設定でプロバイダーとして設定されている必要があります。別のプロバイダーを使用する場合は `--model` で上書きしてください。
- `/experimental/tool/ids` エンドポイントは現在opencode APIの `experimental` 配下にあります。SDKが将来の移行を追跡するはずですが、破損の可能性はあります。
- 大きなマークダウンファイルはモデルのコンテキストウィンドウを超える可能性があります。チャンク分割は行わず、1つのプロンプトでファイル全体を翻訳します。
