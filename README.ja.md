# Monorepo

pnpmワークスペースとVite+を使用したマルチ言語モノレポ（TypeScript + MoonBit）

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

- `Devbox`: `https://www.jetify.com/docs/devbox/installing-devbox`
- `vite-plus(vp)`: `curl -fsSL https://vite.plus | bash`
- `moonbit`: `curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash`
- `atlas`: `curl -sSf https://atlasgo.sh | sh`

### インストール

```bash
# 開発環境に入る
devbox shell

# 依存関係をインストール
vp i
```

## 開発コマンド

[CLAUDE.md > 開発コマンド](./CLAUDE.md#development-commands)

## ライセンス

プライベートリポジトリ（`@totto2727/fp` はMITライセンス）
