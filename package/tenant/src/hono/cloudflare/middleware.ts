import { Array, Effect, Layer, Option, Schema } from "@totto/function/effect"
import { and, eq, inArray, not } from "drizzle-orm"
import { contextStorage } from "hono/context-storage"
import { createFactory } from "hono/factory"
import { HTTPException } from "hono/http-exception"
import {
  cloudflareAccessOrganizationTable,
  cloudflareAccessUserTable,
  organizationTable,
  parentOrganizationTable,
  userTable,
} from "../../db/table.js"
import * as User from "../../schema/user.js"
import { CUIDGenerator } from "../cuid.js"
import { TenantDatabase } from "../db.js"
import type { Env } from "../env.js"
import { AuthHonoMiddlewares } from "../middleware.js"

const decodeOptionUser = Schema.decodeOption(User.schema)
const factory = createFactory<Env>()

export const d1Live = Layer.effect(
  AuthHonoMiddlewares,
  Effect.gen(function*() {
    const getDB = yield* TenantDatabase
    const cuidGenerator = yield* CUIDGenerator

    return {
      base: factory.createMiddleware(async (c, next) => {
        function updateUser(user: typeof User.schema.Encoded) {
          c.set("user", decodeOptionUser(user))
        }

        const payload = c.var.accessPayload
        const db = getDB()

        // トークンのPayloadからデータを抽出
        const cloudflareUserID = payload.sub
        const cloudflareAccessOrganizationIDArray: string[] =
          // @ts-expect-error -- デフォルトのpayloadに存在しないため
          payload.groups ?? []
        // Payloadに組織情報がない場合エラーにする
        if (Array.isEmptyArray(cloudflareAccessOrganizationIDArray)) {
          throw new HTTPException(403)
        }

        // ユーザーの存在チェックと追加
        let cloudflareAccessUserOption = Option.fromIterable(
          await db
            .select({
              cloudflareAccessID: cloudflareAccessUserTable.cloudflareAccessID,
              id: cloudflareAccessUserTable.id,
            })
            .from(cloudflareAccessUserTable)
            .where(
              eq(
                cloudflareAccessUserTable.cloudflareAccessID,
                cloudflareUserID,
              ),
            ),
        )
        if (Option.isNone(cloudflareAccessUserOption)) {
          const userID = cuidGenerator.pipe(Effect.runSync)
          const result = await db.batch([
            db.insert(userTable).values({ id: userID }),
            db
              .insert(cloudflareAccessUserTable)
              .values({
                cloudflareAccessID: payload.sub,
                id: userID,
              })
              .returning(),
          ] as const)
          cloudflareAccessUserOption = Option.fromIterable(result[1])
        }
        const cloudflareAccessUser = Option.getOrThrow(
          cloudflareAccessUserOption,
        )

        // IDから組織関連の情報を取得
        // 合わせてcloudflare accessの組織IDも結合して取得
        const existParentOrganizationArray = await db
          .select({
            cloudflareAccessOrganizationID:
              cloudflareAccessOrganizationTable.cloudflareAccessID,
            organizationID: parentOrganizationTable.organizationID,
            userID: parentOrganizationTable.userID,
          })
          .from(parentOrganizationTable)
          .innerJoin(
            cloudflareAccessOrganizationTable,
            eq(
              parentOrganizationTable.organizationID,
              cloudflareAccessOrganizationTable.id,
            ),
          )
          .where(eq(parentOrganizationTable.userID, cloudflareAccessUser.id))

        // トークンの組織とParentOrganizationの状態が同一であることを検証する。
        // 一致する場合はコンテキストを更新して先に進める。
        const existParentOrganizationIDSet = new Set(
          existParentOrganizationArray.map(
            (v) => v.cloudflareAccessOrganizationID,
          ),
        )
        const cloudflareAccessOrganizationIDSet = new Set(
          cloudflareAccessOrganizationIDArray,
        )
        if (
          cloudflareAccessOrganizationIDSet.isSubsetOf(
            existParentOrganizationIDSet,
          ) &&
          existParentOrganizationIDSet.isSubsetOf(
            cloudflareAccessOrganizationIDSet,
          ) &&
          Array.isNonEmptyArray(existParentOrganizationArray)
        ) {
          updateUser({
            id: cloudflareAccessUser.id,
            organizationIDArray: Array.map(
              existParentOrganizationArray,
              (v) => v.organizationID,
            ),
          })
          return next()
        }

        // トークンの組織が全てDBに追加されていることを検証する。
        const existCloudflareAccessOrganizationArray = await db
          .select({
            cloudflareAccessID:
              cloudflareAccessOrganizationTable.cloudflareAccessID,
            id: cloudflareAccessOrganizationTable.id,
          })
          .from(cloudflareAccessOrganizationTable)
          .where(
            inArray(
              cloudflareAccessOrganizationTable.cloudflareAccessID,
              cloudflareAccessOrganizationIDArray,
            ),
          )

        let cloudflareAccessOrganizationArray =
          existCloudflareAccessOrganizationArray

        const existCloudflareOrganizationIDSet = new Set(
          existCloudflareAccessOrganizationArray.map(
            (v) => v.cloudflareAccessID,
          ),
        )
        const setOfCloudflareAccessOrganizationThatRequireAddition =
          cloudflareAccessOrganizationIDSet.difference(
            existCloudflareOrganizationIDSet,
          )
        if (setOfCloudflareAccessOrganizationThatRequireAddition.size > 0) {
          const newCloudflareAccessOrganizationArray = Array.fromIterable(
            setOfCloudflareAccessOrganizationThatRequireAddition,
          ).map((cloudflareAccessID) => ({
            cloudflareAccessID,
            id: cuidGenerator.pipe(Effect.runSync),
          }))
          const result = await db.batch([
            db
              .insert(organizationTable)
              .values(
                newCloudflareAccessOrganizationArray.map((v) => ({ id: v.id })),
              ),
            db
              .insert(cloudflareAccessOrganizationTable)
              .values(newCloudflareAccessOrganizationArray)
              .returning(),
          ])
          cloudflareAccessOrganizationArray = [
            ...existCloudflareAccessOrganizationArray,
            ...result[1],
          ]
        }

        // ParentOrganizationへの追加
        const parentOrganizationArray = cloudflareAccessOrganizationArray.map(
          (organization) => ({
            organizationID: organization.id,
            userID: cloudflareAccessUser.id,
          }),
        )
        await db
          .insert(parentOrganizationTable)
          .values(parentOrganizationArray)
          .onConflictDoNothing()

        // 余分なParentOrganizationの削除
        await db.delete(parentOrganizationTable).where(
          and(
            eq(parentOrganizationTable.userID, cloudflareAccessUser.id),
            not(
              inArray(
                parentOrganizationTable.organizationID,
                parentOrganizationArray.map((v) => v.organizationID),
              ),
            ),
          ),
        )

        // 100%実行される想定
        if (Array.isNonEmptyArray(parentOrganizationArray)) {
          updateUser({
            id: cloudflareAccessUser.id,
            organizationIDArray: Array.map(
              parentOrganizationArray,
              (v) => v.organizationID,
            ),
          })
        }

        return next()
      }),
      contextStorage: contextStorage(),
      // requiredOrgID: createMiddleware((_, next) => {
      //   return next()
      // }),
      // requiredUserID: createMiddleware((_, next) => {
      //   return next()
      // }),
    }
  }),
)
