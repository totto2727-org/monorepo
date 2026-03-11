import { Effect } from 'effect'
import { Hono } from 'hono'

export const app = Effect.sync(() => new Hono())
