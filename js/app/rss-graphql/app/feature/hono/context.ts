import { ManagedRuntime } from 'effect'
import { FetchHttpClient } from 'effect/unstable/http'
import type { Context as HonoContext } from 'hono'

const runtime = ManagedRuntime.make(FetchHttpClient.layer)

interface Env {
  Variables: {
    runtime: typeof runtime
  }
}

export type Context = HonoContext<Env>
