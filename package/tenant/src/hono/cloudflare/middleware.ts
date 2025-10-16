import {
  Array,
  Effect,
  Layer,
  Option,
  Predicate,
  Schema,
} from "@totto/function/effect"
import { eq, inArray } from "drizzle-orm"
import { contextStorage } from "hono/context-storage"
import { createFactory } from "hono/factory"
import {
  cloudflareAccessOrganizationTable,
  cloudflareAccessUserTable,
  organizationTable,
  userTable,
} from "../../db/table.js"
import { User } from "../../schema.js"
import { CUIDGenerator } from "../cuid.js"
import { TenantDatabase } from "../db.js"
import type { Env } from "../env.js"
import {
  AuthHonoMiddlewares,
  makeRequireUserMiddleware,
} from "../middleware.js"

const decodeOptionUser = Schema.decodeOption(User.schema)
const factory = createFactory<Env>()

export const d1Live = Layer.effect(
  AuthHonoMiddlewares,
  Effect.gen(function* () {
    const getDB = yield* TenantDatabase
    const cuidGenerator = yield* CUIDGenerator

    const requireUser = yield* makeRequireUserMiddleware

    return {
      base: factory.createMiddleware(async (c, next) => {
        function updateUser(user: typeof User.schema.Encoded) {
          c.set("user", decodeOptionUser(user))
        }

        const db = getDB()

        // 認証情報がない場合、noneとなる
        const payload = c.var.accessPayload
        if (Predicate.isNullable(payload)) {
          c.set("user", Option.none())
          return
        }

        // トークンのPayloadからデータを抽出
        const cloudflareUserID = payload.sub
        const cloudflareAccessOrganizationIDArray: string[] =
          // @ts-expect-error -- デフォルトのpayloadに存在しないため
          payload.groups ?? []

        // ユーザーの取得
        let userOption = Option.fromIterable(
          await db
            .select({
              id: userTable.id,
              name: userTable.name,
            })
            .from(cloudflareAccessUserTable)
            .innerJoin(
              userTable,
              eq(cloudflareAccessUserTable.id, userTable.id),
            )
            .where(
              eq(
                cloudflareAccessUserTable.cloudflareAccessID,
                cloudflareUserID,
              ),
            ),
        )

        // ユーザーの追加
        if (Option.isNone(userOption)) {
          const userID = cuidGenerator.pipe(Effect.runSync)
          const result = await db.batch([
            db
              .insert(userTable)
              .values({
                id: userID,
                // name部分はpayloadからとっても良いかも？
                name: userID,
              })
              .returning(),
            db.insert(cloudflareAccessUserTable).values({
              cloudflareAccessID: cloudflareUserID,
              id: userID,
            }),
            db
              .insert(organizationTable)
              .values({ id: userID, isPersonal: true, name: userID }),
          ] as const)
          userOption = Option.fromIterable(result[0])
        }

        const user = Option.getOrThrow(userOption)

        // TODO: 取得タイミングの最適化
        const personalOrganization = Option.fromIterable(
          await db
            .select({
              id: organizationTable.id,
              isPersonal: organizationTable.isPersonal,
              name: organizationTable.name,
            })
            .from(organizationTable)
            .where(eq(organizationTable.id, user.id)),
        ).pipe(Option.getOrThrow)

        if (Array.isEmptyArray(cloudflareAccessOrganizationIDArray)) {
          updateUser({
            id: user.id,
            name: user.name,
            organizationArray: Array.of(personalOrganization),
          })
          return next()
        }

        const existOrganizationArray = await db
          .select({
            cloudflareAccessID:
              cloudflareAccessOrganizationTable.cloudflareAccessID,
            id: organizationTable.id,
            isPersonal: organizationTable.isPersonal,
            name: organizationTable.name,
          })
          .from(cloudflareAccessOrganizationTable)
          .innerJoin(
            organizationTable,
            eq(cloudflareAccessOrganizationTable.id, organizationTable.id),
          )
          .where(
            inArray(
              cloudflareAccessOrganizationTable.cloudflareAccessID,
              cloudflareAccessOrganizationIDArray,
            ),
          )
          .orderBy(organizationTable.createdAt)

        const cloudflareAccessOrganizationIDSet = new Set(
          cloudflareAccessOrganizationIDArray,
        )
        const existCloudflareAccessOrganizationIDSet = new Set(
          existOrganizationArray.map((v) => v.cloudflareAccessID),
        )

        if (
          cloudflareAccessOrganizationIDSet.isSubsetOf(
            existCloudflareAccessOrganizationIDSet,
          ) &&
          existCloudflareAccessOrganizationIDSet.isSubsetOf(
            cloudflareAccessOrganizationIDSet,
          ) &&
          Array.isNonEmptyArray(existOrganizationArray)
        ) {
          updateUser({
            id: user.id,
            name: user.name,
            organizationArray: [
              personalOrganization,
              ...existOrganizationArray,
            ],
          })
          return next()
        }

        const newCloudflareAccessOrganizationIDSet =
          cloudflareAccessOrganizationIDSet.difference(
            existCloudflareAccessOrganizationIDSet,
          )

        const newCloudflareAccessOrganizationArray = Array.fromIterable(
          newCloudflareAccessOrganizationIDSet,
        ).map((cloudflareAccessID) => ({
          cloudflareAccessID,
          id: cuidGenerator.pipe(Effect.runSync),
        }))
        const newOrganizationArray = newCloudflareAccessOrganizationArray.map(
          (v) => ({
            id: v.id,
            isPersonal: false,
            name: v.id,
          }),
        )

        const [, , organizationArray] = await db.batch([
          db.insert(organizationTable).values(newOrganizationArray),
          db
            .insert(cloudflareAccessOrganizationTable)
            .values(newCloudflareAccessOrganizationArray),
          db
            .select({
              cloudflareAccessID:
                cloudflareAccessOrganizationTable.cloudflareAccessID,
              id: organizationTable.id,
              isPersonal: organizationTable.isPersonal,
              name: organizationTable.name,
            })
            .from(cloudflareAccessOrganizationTable)
            .innerJoin(
              organizationTable,
              eq(cloudflareAccessOrganizationTable.id, organizationTable.id),
            )
            .where(
              inArray(
                cloudflareAccessOrganizationTable.cloudflareAccessID,
                cloudflareAccessOrganizationIDArray,
              ),
            )
            .orderBy(organizationTable.createdAt),
        ])

        updateUser({
          id: user.id,
          name: user.name,
          organizationArray: Array.make(
            personalOrganization,
            ...organizationArray,
          ),
        })

        return next()
      }),
      contextStorage: contextStorage(),
      requireUser,
    }
  }),
)
