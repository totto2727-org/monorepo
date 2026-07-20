# Monorepo

BunワークスペースとVite+を使用したマルチ言語モノレポ（TypeScript + MoonBit）

## プロジェクト構成

### 言語別ワークスペース

- `mbt/`: Moonbitプロジェクト
- `js/`: JavaScriptプロジェクト
- `go/`: Goプロジェクト

#### ワークスペース構造

- `apps/`: アプリケーションプロジェクト
- `packages/`: 共有パッケージ

## 開発環境のセットアップ

### 要件

- `Nix`: `https://nixos.org/download/`
- `direnv`: `https://direnv.net/docs/installation.html`（任意）
- `vite-plus(vp)`: `curl -fsSL https://vite.plus | bash`
- `atlas`: `curl -sSf https://atlasgo.sh | sh`

### インストール

```bash
# 開発環境に入る
nix develop

# 依存関係をインストール
vp i
```

開発環境を自動的に読み込む場合は、初回のみ `direnv allow` を実行します。

## 開発コマンド

[CLAUDE.md > 開発コマンド](./CLAUDE.md#development-commands)

## ライセンス

プライベートリポジトリ（`@totto2727/fp` はMITライセンス）
