import type { Context as HonoContext } from "hono"
import { createFactory } from "hono/factory"
import { useRequestContext as useHonoRequestContext } from "hono/jsx-renderer"

type Env = { Bindings: Cloudflare.Env }

export type Context = HonoContext<Env>

export const factory = createFactory<Env>()

export function useRequestContext() {
  return useHonoRequestContext<Env>()
}
