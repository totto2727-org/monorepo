import {
  WorkflowEntrypoint,
  type WorkflowEvent,
  type WorkflowStep,
} from "cloudflare:workers"
import path from "node:path"
import { Array, Effect, pipe } from "@totto/function/effect"
import { save } from "./sync/r2-storage.js"
import { retrieve } from "./sync/retrieve.js"
import * as DataSourceConfig from "./sync/type/data-source-config.js"

export class DataSyncWorkflow extends WorkflowEntrypoint<
  Cloudflare.Env,
  Params
> {
  override async run(_event: WorkflowEvent<Params>, step: WorkflowStep) {
    await step.do("sync files", async () => {
      return pipe(
        createDataSourceConfigArray(),
        Array.flatMap((c) => syncDataSources(this.env.DATA_SOURCE, c)),
        Effect.all,
        Effect.asVoid,
        Effect.runPromise,
      )
    })
  }
}

function syncDataSources(r2: R2Bucket, config: typeof DataSourceConfig.schema.Type) {
  return config.dataSources.map((source) =>
    Effect.gen(function* () {
      switch (source.type) {
        case "text": {
          const filename = path
            .join(source.url.hostname, source.url.pathname)
            .split("/")
            .join("-")
            .replaceAll(".", "-")

          const result = yield* retrieve(source)

          yield* Effect.tryPromise(() =>
            save(
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

function createDataSourceConfigArray(): Array<typeof DataSourceConfig.schema.Type> {
  return [
    {
      dataSources: [
        { type: "text", url: new URL("https://effect.website/llms-full.txt") },
      ],
      mcpToolName: "effect",
    },
  ]
}
