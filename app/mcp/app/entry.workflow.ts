import {
  env,
  WorkflowEntrypoint,
  type WorkflowEvent,
  type WorkflowStep,
} from "cloudflare:workers"
import path from "node:path"
import { Array, Effect, pipe } from "@totto/function/effect"
import { save } from "./sync/r2-storage.js"
import { retrieve } from "./sync/retrieve.js"
import type { DataSourceConfig } from "./sync/types.js"

export class DataSyncWorkflow extends WorkflowEntrypoint<
  Cloudflare.Env,
  Params
> {
  override async run(_event: WorkflowEvent<Params>, step: WorkflowStep) {
    await step.do("sync files", async () => {
      return pipe(
        createDataSourceConfigArray(env),
        Array.flatMap((c) => syncDataSources(c)),
        Effect.all,
        Effect.asVoid,
        Effect.runPromise,
      )
    })
  }
}

function syncDataSources(config: DataSourceConfig) {
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
            save(config.r2Bucket, filename, result.value, result.source.type),
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

function createDataSourceConfigArray(env: Cloudflare.Env): DataSourceConfig[] {
  return [
    {
      dataSources: [
        { type: "text", url: new URL("https://effect.website/llms-full.txt") },
      ],
      r2Bucket: env.EFFECT_DATA_SOURCE,
    },
  ]
}
