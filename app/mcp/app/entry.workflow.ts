import {
  WorkflowEntrypoint,
  type WorkflowEvent,
  type WorkflowStep,
} from "cloudflare:workers"
import path from "node:path"
import { Array, Effect, pipe } from "@totto/function/effect"
import * as Database from "./feature/database.js"
import * as R2Storage from "./feature/sync/r2-storage.js"
import * as Retrieve from "./feature/sync/retrieve.js"
import type * as DataSourceConfig from "./feature/sync/type/data-source-config.js"

export class DataSyncWorkflow extends WorkflowEntrypoint<
  Cloudflare.Env,
  Params
> {
  override async run(_event: WorkflowEvent<Params>, step: WorkflowStep) {
    const db = Database.create(this.env.DB)

    await step.do("sync files", async () =>
      pipe(
        await createDataSourceConfigArray(db),
        Array.flatMap((c) => syncDataSources(this.env.DATA_SOURCE, c)),
        Effect.all,
        Effect.asVoid,
        Effect.runPromise,
      ),
    )
  }
}

function syncDataSources(
  r2: R2Bucket,
  config: typeof DataSourceConfig.schema.Type,
) {
  return config.dataSources.map((source) =>
    Effect.gen(function* () {
      // biome-ignore lint/style/useDefaultSwitchClause: No use default switch clause
      switch (source.type) {
        case "text": {
          const filename = path
            .join(source.url.hostname, source.url.pathname)
            .split("/")
            .join("-")
            .replaceAll(".", "-")

          const result = yield* Retrieve.retrieve(source)

          yield* Effect.tryPromise(() =>
            R2Storage.save(
              r2,
              path.join(config.mcpToolName, filename),
              result.value,
              result.source.type,
            ),
          )
          yield* Effect.logInfo(filename)

          return
        }
        case "firecrawl": {
          return
        }
      }
    }).pipe(
      Effect.catchAll(
        Effect.fn(function* (e) {
          yield* Effect.logError(e)
          return Effect.asVoid
        }),
      ),
    ),
  )
}

function createDataSourceConfigArray(
  db: Database.Database,
): Promise<(typeof DataSourceConfig.schema.Type)[]> {
  return Effect.gen(function* () {
    const dataSourceArray = yield* Effect.tryPromise(() =>
      db.query.dataSourceTable.findMany({
        columns: {
          mcpToolName: true,
          type: true,
          url: true,
        },
        orderBy(fields, operators) {
          return operators.desc(fields.createdAt)
        },
      }),
    )

    const groupedDataSources = Array.groupBy(
      dataSourceArray,
      (dataSource) => dataSource.mcpToolName,
    )

    return Object.entries(groupedDataSources).map(
      ([mcpToolName, dataSources]) => ({
        dataSources: dataSources.map((ds) => ({
          type: ds.type,
          url: new URL(ds.url),
        })),
        mcpToolName,
      }),
    )
  }).pipe(Effect.runPromise)
}
