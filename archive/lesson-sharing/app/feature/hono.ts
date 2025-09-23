import { getContext as getContextFromASL } from "hono/context-storage"
import type { Env } from "#@/types/hono.js"

export const getContext = () => getContextFromASL<Env>()
