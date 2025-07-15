import type { Context } from "hono"
import type { PlatformProxy } from "wrangler"
import type { Env } from "./hono.js"

type GetLoadContextArgs = {
  request: Request
  context: {
    cloudflare: Omit<
      PlatformProxy<Env["Bindings"]>,
      "dispose" | "caches" | "cf"
    > & {
      caches: PlatformProxy<Env>["caches"] | CacheStorage
      cf: Request["cf"]
    }
    hono: {
      context: Context<Env>
    }
  }
}

declare module "react-router" {
  interface AppLoadContext extends ReturnType<typeof getLoadContext> {
    // This will merge the result of `getLoadContext` into the `AppLoadContext`
    extra: string
    hono: {
      context: Context<Env>
    }
  }
}

export function getLoadContext({ context }: GetLoadContextArgs) {
  return {
    ...context,
    extra: "stuff",
  }
}
