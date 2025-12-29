import { STATUS_CODE } from "@package/constant"
import { HTTPError, toHonoResponse } from "@package/error"
import { Effect, Match, Option, Runtime, Schema } from "@totto/function/effect"
import * as CUID from "@totto/function/effect/cuid"
import { and, eq, inArray } from "drizzle-orm"
import { createMiddleware } from "hono/factory"
import * as Table from "../../db/table.js"
import { type JWTUser, User } from "../../schema.js"
import * as HonoContext from "../context.js"
import * as DB from "../db.js"
import * as JWT from "./jwt.js"

const decodeOptionUser = Schema.decodeOption(User.schema)

const provider = "cloudflare-access"

const setNone = Effect.gen(function* () {
  ;(yield* HonoContext.Context)().set("user", Option.none())
})

const updateUserLink = Effect.fn(function* (args: {
  user: {
    id: string
    name: string
  }
  jwtUser: typeof JWTUser.schema.Encoded
}) {
  const db = (yield* DB.TenantDatabase)()

  const userLink = yield* Option.fromIterable(
    yield* Effect.tryPromise(() =>
      db
        .select({
          providerUserEmail: Table.userLinkTable.providerUserEmail,
        })
        .from(Table.userLinkTable)
        .where(
          and(
            eq(Table.userLinkTable.userId, args.user.id),
            eq(Table.userLinkTable.provider, provider),
          ),
        ),
    ),
  )

  // user_link.providerUserEmailが一致しない場合は更新する
  if (userLink.providerUserEmail !== args.jwtUser.email) {
    yield* Effect.tryPromise(
      async () =>
        await db
          .update(Table.userLinkTable)
          .set({
            providerUserEmail: args.jwtUser.email,
          })
          .where(
            and(
              eq(Table.userLinkTable.userId, args.user.id),
              eq(Table.userLinkTable.provider, provider),
            ),
          ),
    )
  }
})

const setUser = Effect.fn(function* (args: {
  user: {
    id: string
    name: string
  }
  jwtUser: typeof JWTUser.schema.Encoded
}) {
  const db = (yield* DB.TenantDatabase)()

  const [
    personalOrganizationResult,
    primaryUserLinkResult,
    existOrganizationArray,
  ] = yield* Effect.tryPromise(() =>
    db.batch([
      db
        .select({
          id: Table.organizationTable.id,
          isPersonal: Table.organizationTable.isPersonal,
          name: Table.organizationTable.name,
        })
        .from(Table.organizationTable)
        .where(
          and(
            eq(Table.organizationTable.id, args.user.id),
            eq(Table.organizationTable.isPersonal, true),
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
            eq(Table.primaryUserLinkTable.userId, Table.userLinkTable.userId),
            eq(
              Table.primaryUserLinkTable.provider,
              Table.userLinkTable.provider,
            ),
          ),
        )
        .where(and(eq(Table.primaryUserLinkTable.userId, args.user.id))),
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
              args.jwtUser.organizationArray.map((v) => v.id),
            ),
            eq(Table.organizationLinkTable.provider, provider),
          ),
        )
        .orderBy(Table.organizationTable.createdAt),
    ] as const),
  )

  const personalOrganization = yield* Option.fromIterable(
    personalOrganizationResult,
  )
  const primaryUserLink = yield* Option.fromIterable(primaryUserLinkResult)

  ;(yield* HonoContext.Context)().set(
    "user",
    decodeOptionUser({
      id: args.user.id,
      name: args.user.name,
      organizationArray: [personalOrganization, ...existOrganizationArray],
      primaryUserLink,
    }),
  )
})

const verifyUserAndOrganization = Effect.fn(function* (
  next: () => Promise<void>,
) {
  // データベースの初期化
  yield* DB.TenantDatabaseInitializer
  const db = (yield* DB.TenantDatabase)()

  // 認証情報がない場合、noneとなる
  const jwtUserOption = (yield* JWT.JWTUser)()
  if (Option.isNone(jwtUserOption)) {
    yield* setNone
    yield* Effect.tryPromise(next)
    return
  }
  const jwtUser = jwtUserOption.value

  // アプリケーションのaudienceに一致しない場合はエラーを返す
  // TODO: 不要かも？
  // https://github.com/honojs/hono/releases/tag/v4.10.2
  if (
    !(yield* JWT.JWTAudience)().includes((yield* JWT.ApplicationAudience)())
  ) {
    return (yield* HonoContext.Context)().json(
      ...toHonoResponse(new HTTPError(STATUS_CODE.UNAUTHORIZED)),
    )
  }

  const userOption = Option.fromIterable(
    yield* Effect.tryPromise(() =>
      db
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
        ),
    ),
  )

  if (Option.isSome(userOption)) {
    yield* setUser({
      jwtUser,
      user: userOption.value,
    })
    yield* Effect.tryPromise(next)
    return
  }

  // user_link.providerUserEmailに一致するものが存在するか確認する
  const userLinkOption = Option.fromIterable(
    yield* Effect.tryPromise(() =>
      db
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
    ),
  )

  const user = yield* Match.value(userLinkOption).pipe(
    // 存在する場合はuser_linkを追加するのみとする
    Match.tag("Some", (userFoundByEmail) =>
      Effect.gen(function* () {
        yield* Effect.tryPromise(() =>
          db.insert(Table.userLinkTable).values({
            provider,
            providerUserEmail: jwtUser.email,
            providerUserId: jwtUser.id,
            userId: userFoundByEmail.value.id,
          }),
        )
        return userFoundByEmail.value
      }),
    ),
    // 存在しない場合はuserとuser_linkとprimary_user_linkとorganization（個人）を追加する
    Match.tag("None", () =>
      Effect.gen(function* () {
        const userID = (yield* CUID.Generator).pipe(Effect.runSync)
        // biome-ignore lint/nursery/noShadow: shadowing is intentional
        const user = {
          id: userID,
          name: jwtUser.name,
        }
        yield* Effect.tryPromise(() =>
          db.batch([
            db.insert(Table.userTable).values(user),
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
          ] as const),
        )
        return user
      }),
    ),
    Match.exhaustive,
  )

  yield* updateUserLink({
    jwtUser,
    user,
  })

  yield* setUser({
    jwtUser,
    user,
  })

  return yield* Effect.tryPromise(next)
})

export const makeVerifyUserAndOrganizationMiddleware = Effect.gen(function* () {
  const runtime =
    yield* Effect.runtime<
      Effect.Effect.Context<ReturnType<typeof verifyUserAndOrganization>>
    >()

  return createMiddleware((_, next) =>
    Effect.gen(function* () {
      return yield* verifyUserAndOrganization(next)
    }).pipe(Runtime.runPromise(runtime)),
  )
})
