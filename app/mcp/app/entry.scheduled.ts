import * as path from "node:path"
import { Array, Effect, pipe } from "@totto/function/effect"
import { fetch } from "#@/sync/fetch.js"
import { save } from "#@/sync/r2-storage.js"
import type { DataSourceConfig } from "#@/sync/types.js"

function syncDataSources(config: DataSourceConfig) {
  return config.dataSources.map((source) =>
    Effect.gen(function* () {
      switch (source.type) {
        case "http": {
          const filename = path
            .join(source.url.hostname, source.url.pathname)
            .split("/")
            .join("-")
            .replaceAll(".", "-")

          const result = yield* fetch(source)

          yield* Effect.tryPromise(() =>
            save(config.r2Bucket, filename, result.value),
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
        { type: "http", url: new URL("https://effect.website/llms-full.txt") },
      ],
      r2Bucket: env.EFFECT_DATA_SOURCE,
    },
  ]
}

export function scheduled(
  _event: ScheduledEvent,
  env: Cloudflare.Env,
): Promise<void> {
  return pipe(
    createDataSourceConfigArray(env),
    Array.flatMap((c) => syncDataSources(c)),
    Effect.all,
    Effect.asVoid,
    Effect.runPromise,
  )
}
