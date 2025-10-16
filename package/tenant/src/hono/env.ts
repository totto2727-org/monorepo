import type { CloudflareAccessVariables } from "@hono/cloudflare-access"
import type { Option } from "@totto/function/effect"
import type { AnyDrizzleD1Database } from "../db/type.js"
import type * as User from "../schema/user.js"

export type Env = {
  Variables: {
    tenantDatabase: AnyDrizzleD1Database
    user: Option.Option<typeof User.schema.Type>
    groups: string[]
  } & CloudflareAccessVariables
}
