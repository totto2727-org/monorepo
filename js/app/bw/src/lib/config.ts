import { readFile } from 'node:fs/promises'

import { Effect, Option, Predicate, Schema } from 'effect'

import { ConfigFileError } from '#@/lib/errors.ts'
import { InputError } from '#@/lib/input-error.ts'
import { ConfigFile } from '#@/schema/config-file.ts'

const decodeConfigFile = Schema.decodeUnknownEffect(ConfigFile)

export const loadConfig = (
  configPath: Option.Option<string>,
): Effect.Effect<Record<string, unknown>, ConfigFileError> =>
  Effect.gen(function* () {
    if (Option.isNone(configPath)) {
      return {}
    }

    const text = yield* Effect.tryPromise({
      catch: (error) =>
        new ConfigFileError({
          message: error instanceof Error ? error.message : String(error),
          path: configPath.value,
        }),
      try: () => readFile(configPath.value, 'utf8'),
    })

    const parsed: unknown = yield* Effect.try({
      catch: (error) =>
        new ConfigFileError({
          message: error instanceof Error ? error.message : String(error),
          path: configPath.value,
        }),
      try: (): unknown => JSON.parse(text),
    })

    return yield* decodeConfigFile(parsed).pipe(
      Effect.mapError(
        (e) =>
          new ConfigFileError({ message: e instanceof Error ? e.message : JSON.stringify(e), path: configPath.value }),
      ),
    )
  })

export const resolveInput = (
  urlFlag: Option.Option<string>,
  htmlFlag: Option.Option<string>,
  config: Record<string, unknown>,
): Effect.Effect<Record<string, unknown>, InputError> =>
  Effect.gen(function* () {
    if (Option.isSome(urlFlag)) {
      return { ...config, url: urlFlag.value }
    }

    if (Option.isSome(htmlFlag)) {
      const htmlContent = yield* Effect.tryPromise({
        catch: (error) =>
          new InputError({
            message: `Failed to read HTML file: ${error instanceof Error ? error.message : String(error)}`,
          }),
        try: () => readFile(htmlFlag.value, 'utf8'),
      })
      return { ...config, html: htmlContent }
    }

    if ('url' in config || 'html' in config) {
      return config
    }

    return yield* new InputError({ message: 'Either --url or --html is required' })
  })

export const applyWaitUntil = (
  body: Record<string, unknown>,
  waitUntil: Option.Option<string>,
): Record<string, unknown> => {
  if (Option.isNone(waitUntil)) {
    return body
  }
  const existing = body['gotoOptions']
  const gotoBase = Predicate.isObject(existing) ? existing : {}
  return {
    ...body,
    gotoOptions: { ...gotoBase, waitUntil: waitUntil.value },
  }
}
