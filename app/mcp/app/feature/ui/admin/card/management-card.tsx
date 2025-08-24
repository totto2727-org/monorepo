import type { FC } from "hono/jsx"

type ManagementCardProps = {
  icon: FC<{ ariaLabel: string; size: "sm" | "md" | "lg" }>
  iconLabel: string
  title: string
  description: string
  href: string
}

export function ManagementCard({
  icon: Icon,
  iconLabel,
  title,
  description,
  href,
}: ManagementCardProps) {
  return (
    <div class="card bg-base-100 shadow-lg">
      <div class="card-body">
        <h2 class="card-title flex items-center gap-2">
          <Icon ariaLabel={iconLabel} size="md" />
          {title}
        </h2>
        <p class="text-base-content/70">{description}</p>
        <div class="card-actions justify-end mt-4">
          <a class="btn btn-primary" href={href}>
            Manage
          </a>
        </div>
      </div>
    </div>
  )
}
