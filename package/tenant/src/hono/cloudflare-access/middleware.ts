import { STATUS_CODE } from "@package/constant"
import {
  Array,
  Effect,
  Layer,
  Option,
  Predicate,
  Schema,
} from "@totto/function/effect"
import * as CUID from "@totto/function/effect/cuid"
import { eq, inArray } from "drizzle-orm"
import type { Context } from "hono"
import { contextStorage } from "hono/context-storage"
import { createFactory } from "hono/factory"
import { HTTPException } from "hono/http-exception"
import {
  cloudflareAccessOrganizationTable,
  cloudflareAccessUserTable,
  organizationTable,
  userTable,
} from "../../db/cloudflare-access.js"
import { User } from "../../schema.js"
import { TenantDatabase, TenantDatabaseInitializer } from "../db.js"
import type { Env } from "../env.js"
import * as Middleware from "../middleware.js"
import { ApplicationAudience, JWTAudience, JWTUser } from "./jwt.js"

const decodeOptionUser = Schema.decodeOption(User.schema)
const factory = createFactory<Env>()

function updateUser(c: Context<Env>, user: typeof User.schema.Encoded) {
  c.set("user", decodeOptionUser(user))
}

export const live = Layer.effect(
  Middleware.AuthHonoMiddlewares,
  Effect.gen(function* () {
    const requireUser = yield* Middleware.makeRequireUserMiddleware

    const initializeDatabase = yield* TenantDatabaseInitializer
    const getDatabase = yield* TenantDatabase
    const makeCUID = yield* CUID.Generator

    const getApplicationAudience = yield* ApplicationAudience
    const getJWTAudience = yield* JWTAudience
    const getJWTUser = yield* JWTUser

    return {
      base: factory.createMiddleware(async (c, next) => {
        initializeDatabase()

        if (!getJWTAudience().includes(getApplicationAudience())) {
          throw new HTTPException(STATUS_CODE.UNAUTHORIZED)
        }

        // 認証情報がない場合、noneとなる
        const jwtUser = getJWTUser()
        if (Predicate.isNullable(jwtUser.id)) {
          c.set("user", Option.none())
          return next()
        }

        // トークンのPayloadからデータを抽出
        const cloudflareAccessUserID = jwtUser.id
        const cloudflareAccessOrganizationIDArray: string[] =
          jwtUser.organizationIDArray

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
          const userID = makeCUID.pipe(Effect.runSync)
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
          updateUser(c, {
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
          updateUser(c, {
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
          id: makeCUID.pipe(Effect.runSync),
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

        updateUser(c, {
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
