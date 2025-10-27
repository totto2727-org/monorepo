import type { PropsWithChildren } from "hono/jsx"

export function H1Container(props: PropsWithChildren) {
  return (
    <div class="flex flex-col items-center justify-between gap-6 text-center lg:flex-row lg:text-start">
      {props.children}
    </div>
  )
}
