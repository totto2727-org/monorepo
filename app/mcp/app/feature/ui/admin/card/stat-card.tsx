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
        <p class="font-bold text-2xl">{value}</p>
        <p class="text-base-content/70 text-sm">{description}</p>
      </div>
    </div>
  )
}
