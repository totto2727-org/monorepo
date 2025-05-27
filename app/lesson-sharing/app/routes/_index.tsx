import { Button } from "@yamada-ui/react"
import type { Route } from "./+types/_index"

export const loader = (args: Route.LoaderArgs) => {
  const extra = args.context.extra
  const cloudflare = args.context.cloudflare
  const isWaitUntilDefined = !!cloudflare.ctx.waitUntil
  return { cloudflare, extra, isWaitUntilDefined }
}

export default function Index({ loaderData }: Route.ComponentProps) {
  const { cloudflare, extra, isWaitUntilDefined } = loaderData
  return (
    <div>
      <h1>React Router and Hono</h1>
      <h3>
        {cloudflare.cf ? "cf," : ""}
        {cloudflare.ctx ? "ctx," : ""}
        {cloudflare.caches ? "caches are available" : ""}
      </h3>
      <h4>Extra is {extra}</h4>
      <h6>waitUntil is {isWaitUntilDefined ? "defined" : "not defined"}</h6>
      <Button colorScheme="primary">Click me!</Button>
    </div>
  )
}
