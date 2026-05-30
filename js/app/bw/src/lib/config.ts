import { Effect, FileSystem, Option, Predicate, Schema } from 'effect'

import { errorMessageOrDefault } from '#@/lib/error.ts'
import { ConfigFileError } from '#@/lib/errors.ts'
import { InputError } from '#@/lib/input-error.ts'
import { ConfigFile } from '#@/schema/config-file.ts'

// oxlint-disable-next-line rules/prefer-non-unknown-decode -- input is unknown (file content)
const decodeConfigFile = Schema.decodeUnknownEffect(ConfigFile)

export const loadConfig = (
  configPath: Option.Option<string>,
): Effect.Effect<Record<string, unknown>, ConfigFileError, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    if (Option.isNone(configPath)) {
      return {}
    }

    const fs = yield* FileSystem.FileSystem
    const text = yield* fs.readFileString(configPath.value).pipe(
      Effect.mapError(
        (error) =>
          new ConfigFileError({
            message: errorMessageOrDefault(error),
            path: configPath.value,
          }),
      ),
    )

    const parsed: unknown = yield* Effect.try({
      catch: (error) =>
        new ConfigFileError({
          message: errorMessageOrDefault(error),
          path: configPath.value,
        }),
      try: (): unknown => JSON.parse(text),
    })

    return yield* decodeConfigFile(parsed).pipe(
      Effect.mapError(
        (e) => new ConfigFileError({ message: errorMessageOrDefault(e, JSON.stringify(e)), path: configPath.value }),
      ),
    )
  })

export const resolveInput = (
  urlFlag: Option.Option<string>,
  htmlFlag: Option.Option<string>,
  config: Record<string, unknown>,
): Effect.Effect<Record<string, unknown>, InputError, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    if (Option.isSome(urlFlag)) {
      return { ...config, url: urlFlag.value }
    }

    if (Option.isSome(htmlFlag)) {
      const fs = yield* FileSystem.FileSystem
      const htmlContent = yield* fs.readFileString(htmlFlag.value).pipe(
        Effect.mapError(
          (error) =>
            new InputError({
              message: `Failed to read HTML file: ${errorMessageOrDefault(error)}`,
            }),
        ),
      )
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
  const existing = body.gotoOptions
  const gotoBase = Predicate.isObject(existing) ? existing : {}
  return {
    ...body,
    gotoOptions: { ...gotoBase, waitUntil: waitUntil.value },
  }
}
