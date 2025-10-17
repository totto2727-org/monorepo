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
import { TenantDatabase, TenantDatabaseInitializer } from "../db.js"
import type { Env } from "../env.js"
import {
  AuthHonoMiddlewares,
  makeRequireUserMiddleware,
} from "../middleware.js"
import { UserSource } from "./user-source.js"

const decodeOptionUser = Schema.decodeOption(User.schema)
const factory = createFactory<Env>()

export const live = Layer.effect(
  AuthHonoMiddlewares,
  Effect.gen(function* () {
    const initializeDatabase = yield* TenantDatabaseInitializer
    const getDatabase = yield* TenantDatabase
    const cuidGenerator = yield* CUIDGenerator

    const requireUser = yield* makeRequireUserMiddleware

    const getUserUserSource = yield* UserSource

    return {
      base: factory.createMiddleware(async (c, next) => {
        function updateUser(user: typeof User.schema.Encoded) {
          c.set("user", decodeOptionUser(user))
        }

        initializeDatabase()

        // 認証情報がない場合、noneとなる
        const userSource = getUserUserSource()
        if (Predicate.isNullable(userSource.id)) {
          c.set("user", Option.none())
          return next()
        }

        // トークンのPayloadからデータを抽出
        const cloudflareAccessUserID = userSource.id
        const cloudflareAccessOrganizationIDArray: string[] =
          userSource.organizationIDArray

        const db = getDatabase()

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
                cloudflareAccessUserID,
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
              cloudflareAccessID: cloudflareAccessUserID,
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
