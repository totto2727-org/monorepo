type IconProps = {
  size?: "sm" | "md" | "lg"
  className?: string
  ariaLabel?: string
}

const sizeClasses = {
  lg: "w-6 h-6",
  md: "w-5 h-5",
  sm: "w-4 h-4",
}

export function DashboardIcon({
  size = "md",
  className = "",
  ariaLabel = "ダッシュボード",
}: IconProps) {
  return (
    <svg
      aria-label={ariaLabel}
      className={`${sizeClasses[size]} ${className}`}
      fill="none"
      role="img"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
    </svg>
  )
}

export function ServerIcon({
  size = "md",
  className = "",
  ariaLabel = "サーバー",
}: IconProps) {
  return (
    <svg
      aria-label={ariaLabel}
      className={`${sizeClasses[size]} ${className}`}
      fill="none"
      role="img"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        d="M5 12h14M5 12a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v4a2 2 0 01-2 2M5 12a2 2 0 00-2 2v4a2 2 0 002 2h14a2 2 0 002-2v-4a2 2 0 00-2-2m-2-4h.01M17 16h.01"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
    </svg>
  )
}

export function ToolsIcon({
  size = "md",
  className = "",
  ariaLabel = "ツール",
}: IconProps) {
  return (
    <svg
      aria-label={ariaLabel}
      className={`${sizeClasses[size]} ${className}`}
      fill="none"
      role="img"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
      <path
        d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
    </svg>
  )
}

export function SystemIcon({
  size = "md",
  className = "",
  ariaLabel = "システム設定",
}: IconProps) {
  return (
    <svg
      aria-label={ariaLabel}
      className={`${sizeClasses[size]} ${className}`}
      fill="none"
      role="img"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 100 4m0-4v2m0-6V4"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
    </svg>
  )
}

export function MenuIcon({
  size = "md",
  className = "",
  ariaLabel = "メニュー",
}: IconProps) {
  return (
    <svg
      aria-label={ariaLabel}
      className={`${sizeClasses[size]} ${className} inline-block stroke-current`}
      fill="none"
      role="img"
      viewBox="0 0 24 24"
    >
      <path
        d="M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
    </svg>
  )
}

export function PlusIcon({
  size = "md",
  className = "",
  ariaLabel = "追加",
}: IconProps) {
  return (
    <svg
      aria-label={ariaLabel}
      className={`${sizeClasses[size]} ${className}`}
      fill="none"
      role="img"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        d="M12 6v6m0 0v6m0-6h6m-6 0H6"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
    </svg>
  )
}

export function EditIcon({
  size = "md",
  className = "",
  ariaLabel = "編集",
}: IconProps) {
  return (
    <svg
      aria-label={ariaLabel}
      className={`${sizeClasses[size]} ${className}`}
      fill="none"
      role="img"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
    </svg>
  )
}

export function DeleteIcon({
  size = "md",
  className = "",
  ariaLabel = "削除",
}: IconProps) {
  return (
    <svg
      aria-label={ariaLabel}
      className={`${sizeClasses[size]} ${className}`}
      fill="none"
      role="img"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
    </svg>
  )
}

export function CheckIcon({
  size = "md",
  className = "",
  ariaLabel = "確認",
}: IconProps) {
  return (
    <svg
      aria-label={ariaLabel}
      className={`${sizeClasses[size]} ${className}`}
      fill="none"
      role="img"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        d="M5 13l4 4L19 7"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
    </svg>
  )
}

export function RefreshIcon({
  size = "md",
  className = "",
  ariaLabel = "更新",
}: IconProps) {
  return (
    <svg
      aria-label={ariaLabel}
      className={`${sizeClasses[size]} ${className}`}
      fill="none"
      role="img"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
    </svg>
  )
}

export function LightningIcon({
  size = "md",
  className = "",
  ariaLabel = "クイックアクション",
}: IconProps) {
  return (
    <svg
      aria-label={ariaLabel}
      className={`${sizeClasses[size]} ${className}`}
      fill="none"
      role="img"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        d="M13 10V3L4 14h7v7l9-11h-7z"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
    </svg>
  )
}

export function WarningIcon({
  size = "md",
  className = "",
  ariaLabel = "警告",
}: IconProps) {
  return (
    <svg
      aria-label={ariaLabel}
      className={`${sizeClasses[size]} ${className}`}
      fill="none"
      role="img"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16c-.77.833.192 2.5 1.732 2.5z"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
    </svg>
  )
}

export function InfoIcon({
  size = "md",
  className = "",
  ariaLabel = "情報",
}: IconProps) {
  return (
    <svg
      aria-label={ariaLabel}
      className={`${sizeClasses[size]} ${className}`}
      fill="none"
      role="img"
      stroke="currentColor"
      viewBox="0 0 24 24"
    >
      <path
        d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
      />
    </svg>
  )
}
