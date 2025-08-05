# MCP UI コーディング規約

このドキュメントは、MCPアプリケーションのUI開発における一貫したコーディングスタイルとベストプラクティスを定義します。

## 目次

1. [基本原則](#基本原則)
2. [プロジェクト構成](#プロジェクト構成)
3. [コンポーネント設計](#コンポーネント設計)
4. [スタイリング規約](#スタイリング規約)
5. [アクセシビリティ](#アクセシビリティ)
6. [インタラクティブ要素](#インタラクティブ要素)
7. [型安全性](#型安全性)
8. [パフォーマンス](#パフォーマンス)

## 基本原則

### 1. 一貫性の維持
- コードベース全体で統一されたパターンを使用
- 既存のコンポーネントと命名規則に従う
- プロジェクト固有の慣例を優先

### 2. 保守性の重視
- 再利用可能なコンポーネントの作成
- 関心の分離（UI、ロジック、データ）
- 明確で自己文書化するコード

### 3. アクセシビリティファースト
- すべてのUI要素にアクセシビリティを考慮
- セマンティックHTMLの使用
- スクリーンリーダー対応

## プロジェクト構成

### ディレクトリ構造
```
app/admin/
├── pages/          # ページコンポーネント
│   ├── layout.tsx  # 共通レイアウト
│   ├── dashboard.tsx
│   ├── server.tsx
│   └── tools.tsx
├── ui/             # UI コンポーネント
│   ├── icons/      # アイコンコンポーネント
│   │   └── icon.tsx
│   └── layout/     # レイアウト関連
│       ├── htmx.tsx
│       ├── tailwind.tsx
│       └── tailwind.css
└── api/            # API関連（将来拡張用）
```

### ファイル命名規則
- **コンポーネント**: PascalCase (`Dashboard.tsx`, `ServerConfig.tsx`)
- **ユーティリティ**: camelCase (`apiClient.ts`, `formatDate.ts`)
- **設定ファイル**: kebab-case (`tailwind.css`, `api-config.ts`)

## コンポーネント設計

### 1. 関数コンポーネント
**✅ 良い例:**
```tsx
export function Dashboard() {
  const stats = {
    serverName: "totto-docs-mcp-server",
    version: "1.0.0"
  }
  
  return (
    <div class="space-y-6">
      <h1 class="text-3xl font-bold">ダッシュボード</h1>
      {/* コンテンツ */}
    </div>
  )
}
```

**❌ 避けるべき:**
```tsx
// アロー関数は避ける
const Dashboard = () => { /* ... */ }

// デフォルトエクスポートは避ける
export default Dashboard
```

### 2. プロパティ定義
**✅ 良い例:**
```tsx
interface IconProps {
  size?: "sm" | "md" | "lg"
  className?: string
  ariaLabel?: string
}

export function PlusIcon({ 
  size = "md", 
  className = "", 
  ariaLabel = "追加" 
}: IconProps) {
  // 実装
}
```

### 3. 条件付きレンダリング
**✅ 良い例:**
```tsx
{tools.length > 0 && (
  <div class="space-y-3">
    {tools.map((tool) => (
      <ToolItem key={tool.id} tool={tool} />
    ))}
  </div>
)}
```

### 4. イベントハンドラー
**✅ 良い例:**
```tsx
<button 
  type="button"
  class="btn btn-primary"
  onclick={`editTool('${tool.id}')`}
>
  編集
</button>
```

## スタイリング規約

### 1. Tailwind CSS
- **クラス順序**: レイアウト → 外観 → インタラクション
- **レスポンシブ**: モバイルファーストアプローチ
- **カスタムクラス**: DaisyUIコンポーネントを優先使用

**✅ 良い例:**
```tsx
<div class="flex flex-col gap-4 p-6 bg-base-100 rounded-lg shadow-lg md:flex-row">
  <button class="btn btn-primary">
    保存
  </button>
</div>
```

### 2. DaisyUI コンポーネント
- 標準的なUI要素にはDaisyUIクラスを使用
- 一貫したテーマカラーの適用

**使用するコンポーネント:**
```tsx
// ナビゲーション
<div class="navbar bg-base-100">
<div class="drawer lg:drawer-open">

// ボタン
<button class="btn btn-primary">
<button class="btn btn-outline">

// カード
<div class="card bg-base-100 shadow-lg">

// フォーム
<div class="form-control">
<input class="input input-bordered">
<textarea class="textarea textarea-bordered">
```

### 3. レスポンシブデザイン
```tsx
// グリッドレイアウト
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">

// フレックスレイアウト
<div class="flex flex-col md:flex-row gap-4">

// 表示制御
<div class="hidden lg:block">
```

## アクセシビリティ

### 1. セマンティックHTML
**✅ 良い例:**
```tsx
<main class="flex-1 p-6">
  <h1 class="text-3xl font-bold">ページタイトル</h1>
  <nav aria-label="メニュー">
    <ul class="menu">
      <li><a href="/admin">ダッシュボード</a></li>
    </ul>
  </nav>
</main>
```

### 2. アイコンのアクセシビリティ
**✅ 必須実装:**
```tsx
export function DashboardIcon({ 
  size = "md", 
  className = "", 
  ariaLabel = "ダッシュボード" 
}: IconProps) {
  return (
    <svg
      className={`${sizeClasses[size]} ${className}`}
      role="img"
      aria-label={ariaLabel}
      // ... その他の属性
    >
      {/* パス要素 */}
    </svg>
  )
}
```

### 3. フォーム要素
**✅ 良い例:**
```tsx
<div class="form-control">
  <label class="label" htmlFor="server-name">
    <span class="label-text font-semibold">サーバー名</span>
    <span class="label-text-alt text-error">必須</span>
  </label>
  <input
    id="server-name"
    type="text"
    name="name"
    class="input input-bordered"
    required
    aria-describedby="server-name-help"
  />
  <label class="label" id="server-name-help">
    <span class="label-text-alt">MCPクライアントに表示される識別名</span>
  </label>
</div>
```

### 4. ボタンとリンク
**✅ 良い例:**
```tsx
// ナビゲーション用（リンク）
<a class="btn btn-primary" href="/app/admin/tools">
  ツール管理
</a>

// アクション用（ボタン）
<button class="btn btn-primary" type="button" onclick="saveConfig()">
  <CheckIcon size="sm" ariaLabel="保存アイコン" />
  保存
</button>

// フォーム送信用
<button class="btn btn-primary" type="submit">
  送信
</button>
```

## インタラクティブ要素

### 1. HTMX の使用
**✅ 推奨パターン:**
```tsx
// レイアウト全体にブースト適用
<div class="min-h-screen bg-base-200" hx-boost="true">

// 部分更新が必要な場合のみ個別指定
<form 
  hx-put="/app/admin/api/server"
  hx-target="#save-status"
  hx-indicator="#save-spinner"
>
```

### 2. モーダルダイアログ
**✅ 良い例:**
```tsx
<dialog id="add-tool-modal" class="modal">
  <div class="modal-box w-11/12 max-w-2xl">
    <h3 class="font-bold text-lg mb-4">新しい検索ツールを追加</h3>
    <form class="space-y-4">
      {/* フォーム内容 */}
    </form>
  </div>
  <form method="dialog" class="modal-backdrop">
    <button>close</button>
  </form>
</dialog>
```

### 3. 状態管理
**✅ 良い例:**
```tsx
// ローディング状態
<div class="htmx-indicator loading loading-spinner loading-sm" id="save-spinner"></div>

// 状態表示
<div class="badge badge-success">稼働中</div>
<div class="badge badge-warning">停止中</div>
```

## 型安全性

### 1. TypeScript型定義
**✅ 良い例:**
```tsx
// インターフェース定義
interface McpSearchTool {
  id: string
  name: string
  title: string
  description: string
  target: TargetDocument
  status: "active" | "inactive"
}

// リテラル型
type TargetDocument = "effect" | "hono" | "react" | "typescript"

// プロパティ型
interface IconProps {
  size?: "sm" | "md" | "lg"
  className?: string
  ariaLabel?: string
}
```

### 2. JSX型注釈
```tsx
import type { JSX } from "hono/jsx"

export function Dashboard(): JSX.Element {
  return <div>...</div>
}
```

## パフォーマンス

### 1. 画像とアセット
**✅ 最適化:**
```tsx
// 開発環境では CDN、本番環境では静的ファイル
export function Tailwind() {
  return import.meta.env.PROD ? (
    <link href="/asset/tailwind.css" rel="stylesheet" />
  ) : (
    <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
  )
}
```

### 2. アイコンコンポーネントの再利用
**✅ 良い例:**
```tsx
// 個別のSVG使用を避け、アイコンコンポーネントを使用
<PlusIcon size="sm" ariaLabel="追加" />
<EditIcon size="sm" ariaLabel="編集" />
<DeleteIcon size="sm" ariaLabel="削除" />
```

## 命名規則

### 1. コンポーネント名
- **ページコンポーネント**: 機能を表す名詞 (`Dashboard`, `ServerConfig`, `ToolsManager`)
- **UIコンポーネント**: 要素の種類 + 目的 (`AdminLayout`, `ToolForm`)
- **アイコンコンポーネント**: 対象 + `Icon` (`DashboardIcon`, `PlusIcon`)

### 2. 関数・変数名
- **関数**: 動詞から始める (`createMcpHandler`, `editTool`, `deleteTool`)
- **変数**: 名詞または形容詞 (`currentConfig`, `availableTargets`, `isLoading`)
- **定数**: UPPER_SNAKE_CASE (`API_BASE_URL`, `DEFAULT_TIMEOUT`)

### 3. CSS クラス名
- Tailwind CSS および DaisyUI の標準クラス名を使用
- カスタムクラスは避け、既存のユーティリティクラスを組み合わせる

## エラーハンドリング

### 1. フォームバリデーション
**✅ 良い例:**
```tsx
<input
  type="text"
  name="name"
  class="input input-bordered"
  required
  pattern="^[a-z][a-z0-9_]*$"
  minLength={3}
  maxLength={50}
/>
```

### 2. エラー表示
**✅ 良い例:**
```tsx
<div class="alert alert-error" role="alert">
  <svg class="w-6 h-6" fill="none" stroke="currentColor">
    {/* エラーアイコン */}
  </svg>
  <span>エラーメッセージ</span>
</div>
```

## テスト考慮事項

### 1. テスタビリティ
- `data-testid` 属性の使用を検討
- 複雑なロジックは別関数に分離
- モック可能な構造設計

### 2. アクセシビリティテスト
- スクリーンリーダーでの動作確認
- キーボードナビゲーションの確認
- カラーコントラストの検証

## 実装チェックリスト

新しいコンポーネントを作成する際は、以下の項目を確認してください：

### 基本実装
- [ ] TypeScript型定義が適切に行われている
- [ ] 関数コンポーネントを使用している（アロー関数ではない）
- [ ] 名前付きエクスポートを使用している
- [ ] 適切なファイル名とディレクトリ配置

### スタイリング
- [ ] Tailwind CSS クラスを使用している
- [ ] DaisyUI コンポーネントを活用している
- [ ] レスポンシブデザインに対応している
- [ ] 一貫したカラーテーマを使用している

### アクセシビリティ
- [ ] セマンティックHTMLを使用している
- [ ] 適切な見出し階層（h1, h2, h3...）
- [ ] ボタンに `type` 属性を指定している
- [ ] フォーム要素に適切な `label` と `id` の関連付け
- [ ] アイコンに `aria-label` と `role="img"` を指定
- [ ] キーボードナビゲーションが機能する

### パフォーマンス
- [ ] 不要な再レンダリングを避けている
- [ ] 適切なキー属性をリスト要素に指定
- [ ] アイコンは再利用可能なコンポーネントを使用

### HTMX統合
- [ ] ナビゲーションには `hx-boost` を使用
- [ ] 部分更新が必要な場合のみ個別のHTMX属性を使用
- [ ] 適切なターゲット要素を指定
- [ ] ローディング状態のインジケーターを実装

## まとめ

このコーディング規約は、MCPアプリケーションのUI開発における品質と一貫性を保つための指針です。新しい機能開発や既存コードの修正時には、これらのルールに従って実装してください。

規約は実装の進展と共に継続的に改善していく必要があります。新しいパターンや改善案があれば、チーム内で議論して更新してください。