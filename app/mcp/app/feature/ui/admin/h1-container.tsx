import type { PropsWithChildren } from "hono/jsx"

export function H1Container(props: PropsWithChildren) {
  return (
    <div class="flex items-center justify-between flex-col lg:flex-row gap-6 text-center lg:text-start">
      {props.children}
    </div>
  )
}
