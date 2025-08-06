type SimpleStatCardProps = {
  title: string
  value: string | number
  colorClass?: string
}

export function SimpleStatCard({
  title,
  value,
  colorClass = "text-primary",
}: SimpleStatCardProps) {
  return (
    <div class="stat bg-base-100 rounded-lg shadow">
      <div class="stat-title">{title}</div>
      <div class={`stat-value ${colorClass}`}>{value}</div>
    </div>
  )
}