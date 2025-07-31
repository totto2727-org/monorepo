import { Schema } from "@totto/function/effect"
import { Cuid } from "@totto/function/effect/id"
import type { organizationTable, userTable } from "../db/schema/table.js"

export const userSchema = Schema.Struct({
  id: Cuid,
  orgID: Schema.Array(Cuid),
})

const user = Schema.decodeSync(userSchema)
export const fromDTOtoUser = (args: {
  userDTO: Pick<typeof userTable.$inferSelect, "id">
  organizationDTOArray: Pick<typeof organizationTable.$inferSelect, "id">[]
}) => {
  return user({
    id: args.userDTO.id,
    orgID: args.organizationDTOArray.map((v) => v.id),
  })
}
