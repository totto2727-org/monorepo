# @package/ui

Shadcn/UI をベースにした React UI コンポーネントライブラリ。Tailwind CSS v4 を使用。

## 技術スタック

- **ベース**: Shadcn/UI コンポーネントパターン
- **スタイリング**: Tailwind CSS v4 + tw-animate-css
- **バリアント**: class-variance-authority (CVA)
- **ユーティリティ**: clsx + tailwind-merge
- **アイコン**: Lucide React
- **型チェック**: vp check

## エクスポート

- `@package/ui/style.css` - グローバルスタイル (Tailwind CSS)
- `@package/ui/utils` - ユーティリティ関数 (cn など)
- `@package/ui/components/*` - React コンポーネント
- `@package/ui/components/ui/*` - UI プリミティブ (button など)
- `@package/ui/hooks/*` - カスタム React フック
- `@package/ui/lib/*` - ライブラリユーティリティ

## 開発

```bash
# 型チェック
vp check
```

## コンポーネントの追加

コンポーネントは `components.json` 設定ファイルを介して管理され、Shadcn/UI CLI 生成に使用されます。