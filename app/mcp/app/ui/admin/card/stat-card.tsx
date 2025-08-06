type StatCardProps = {
  title: string
  value: string | number
  description: string
  colorClass?: string
}

export function StatCard({
  title,
  value,
  description,
  colorClass = "",
}: StatCardProps) {
  return (
    <div class="card bg-base-100 shadow-lg">
      <div class="card-body">
        <h2 class={`card-title ${colorClass}`}>{title}</h2>
        <p class="text-2xl font-bold">{value}</p>
        <p class="text-sm text-base-content/70">{description}</p>
      </div>
    </div>
  )
}