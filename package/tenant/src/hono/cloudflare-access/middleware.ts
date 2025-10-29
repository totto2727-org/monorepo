import { STATUS_CODE } from "@package/constant"
import { Effect, Layer, Option, Schema } from "@totto/function/effect"
import * as CUID from "@totto/function/effect/cuid"
import { and, eq, inArray } from "drizzle-orm"
import type { Context } from "hono"
import { contextStorage } from "hono/context-storage"
import { createFactory } from "hono/factory"
import { HTTPException } from "hono/http-exception"
import * as Table from "../../db/table.js"
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

const provider = "cloudflare-access"

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
        const jwtUserOption = getJWTUser()
        if (Option.isNone(jwtUserOption)) {
          c.set("user", Option.none())
          return next()
        }
        const jwtUser = Option.getOrThrow(jwtUserOption)

        const db = getDatabase()

        // userを取得する
        const userResult = await db
          .select({
            id: Table.userTable.id,
            name: Table.userTable.name,
          })
          .from(Table.userLinkTable)
          .innerJoin(
            Table.userTable,
            eq(Table.userLinkTable.userId, Table.userTable.id),
          )
          .where(
            and(
              eq(Table.userLinkTable.providerUserId, jwtUser.id),
              eq(Table.userLinkTable.provider, provider),
            ),
          )

        let userOption = Option.fromIterable(userResult)

        // ユーザーの追加
        if (Option.isNone(userOption)) {
          // user_link.providerUserEmailに一致するものが存在するか確認する
          const userFindedByEmailOption = Option.fromIterable(
            await db
              .select({
                id: Table.userTable.id,
                name: Table.userTable.name,
              })
              .from(Table.userLinkTable)
              .innerJoin(
                Table.userTable,
                eq(Table.userLinkTable.userId, Table.userTable.id),
              )
              .where(eq(Table.userLinkTable.providerUserEmail, jwtUser.email)),
          )

          if (Option.isSome(userFindedByEmailOption)) {
            // 存在する場合はuser_linkを追加するのみとする
            userOption = userFindedByEmailOption

            await db.insert(Table.userLinkTable).values({
              provider,
              providerUserEmail: jwtUser.email,
              providerUserId: jwtUser.id,
              userId: userFindedByEmailOption.value.id,
            })
          } else {
            // 存在しない場合はuserとuser_linkとprimary_user_linkとorganization（個人）を追加する
            const userID = makeCUID.pipe(Effect.runSync)
            userOption = Option.some({
              id: userID,
              name: jwtUser.name,
            })
            await db.batch([
              db.insert(Table.userTable).values(Option.getOrThrow(userOption)),
              db.insert(Table.userLinkTable).values({
                provider,
                providerUserEmail: jwtUser.email,
                providerUserId: jwtUser.id,
                userId: userID,
              }),
              db.insert(Table.primaryUserLinkTable).values({
                provider,
                userId: userID,
              }),
              db.insert(Table.organizationTable).values({
                id: userID,
                isPersonal: true,
                name: jwtUser.name,
              }),
            ] as const)
          }
        }

        const user = Option.getOrThrow(userOption)

        const [
          personalOrganizationResult,
          userLinkResult,
          primaryUserLinkResult,
          existOrganizationArray,
        ] = await db.batch([
          db
            .select({
              id: Table.organizationTable.id,
              isPersonal: Table.organizationTable.isPersonal,
              name: Table.organizationTable.name,
            })
            .from(Table.organizationTable)
            .where(
              and(
                eq(Table.organizationTable.id, user.id),
                eq(Table.organizationTable.isPersonal, true),
              ),
            ),
          db
            .select({
              providerUserEmail: Table.userLinkTable.providerUserEmail,
            })
            .from(Table.userLinkTable)
            .where(
              and(
                eq(Table.userLinkTable.userId, user.id),
                eq(Table.userLinkTable.provider, provider),
              ),
            ),
          db
            .select({
              provider: Table.userLinkTable.provider,
              providerUserEmail: Table.userLinkTable.providerUserEmail,
            })
            .from(Table.primaryUserLinkTable)
            .innerJoin(
              Table.userLinkTable,
              and(
                eq(
                  Table.primaryUserLinkTable.userId,
                  Table.userLinkTable.userId,
                ),
                eq(
                  Table.primaryUserLinkTable.provider,
                  Table.userLinkTable.provider,
                ),
              ),
            )
            .where(and(eq(Table.primaryUserLinkTable.userId, user.id))),
          db
            .select({
              id: Table.organizationTable.id,
              isPersonal: Table.organizationTable.isPersonal,
              name: Table.organizationTable.name,
              provider: Table.organizationLinkTable.provider,
              providerOrganizationId:
                Table.organizationLinkTable.providerOrganizationId,
            })
            .from(Table.organizationLinkTable)
            .innerJoin(
              Table.organizationTable,
              eq(
                Table.organizationLinkTable.organizationId,
                Table.organizationTable.id,
              ),
            )
            .where(
              and(
                inArray(
                  Table.organizationLinkTable.providerOrganizationId,
                  jwtUser.organizationArray.map((v) => v.id),
                ),
                eq(Table.organizationLinkTable.provider, provider),
              ),
            )
            .orderBy(Table.organizationTable.createdAt),
        ] as const)

        const personalOrganization = Option.getOrThrow(
          Option.fromIterable(personalOrganizationResult),
        )
        const userLink = Option.getOrThrow(Option.fromIterable(userLinkResult))
        const primaryUserLink = Option.getOrThrow(
          Option.fromIterable(primaryUserLinkResult),
        )

        // user_link.providerUserEmailが一致しない場合は更新する
        if (userLink.providerUserEmail !== jwtUser.email) {
          await db
            .update(Table.userLinkTable)
            .set({
              providerUserEmail: jwtUser.email,
            })
            .where(
              and(
                eq(Table.userLinkTable.userId, user.id),
                eq(Table.userLinkTable.provider, provider),
              ),
            )
        }

        updateUser(c, {
          id: user.id,
          name: user.name,
          organizationArray: [personalOrganization, ...existOrganizationArray],
          primaryUserLink,
        })

        return next()
      }),
      contextStorage: contextStorage(),
      requireUser,
    }
  }),
)
