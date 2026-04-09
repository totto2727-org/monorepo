import { readFile } from 'node:fs/promises'

import { Effect, Option } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { applyWaitUntil, loadConfig, resolveInput } from '#@/lib/config.ts'
import * as Flags from '#@/lib/flags.ts'
import * as ApiClient from '#@/service/api-client.ts'
import * as Auth from '#@/service/auth.ts'
import * as Output from '#@/service/output.ts'

export const jsonCommand = Command.make(
  'json',
  {
    accountId: Flags.accountId,
    apiToken: Flags.apiToken,
    config: Flags.config,
    html: Flags.html,
    prompt: Flag.string('prompt').pipe(Flag.withDescription('Natural language extraction prompt')),
    schema: Flag.string('schema').pipe(Flag.optional, Flag.withDescription('Path to JSON Schema file')),
    url: Flags.url,
    waitUntil: Flags.waitUntil,
  },
  (flags) =>
    Effect.gen(function* () {
      const auth = yield* Auth.resolve(flags)
      const config = yield* loadConfig(flags.config)
      const baseBody = yield* resolveInput(flags.url, flags.html, config)
      const bodyWithPrompt = { ...applyWaitUntil(baseBody, flags.waitUntil), prompt: flags.prompt }

      const schemaPath = flags.schema
      const body = Option.isSome(schemaPath)
        ? yield* Effect.tryPromise({
            catch: (error) =>
              new Error(`Failed to read schema file: ${error instanceof Error ? error.message : String(error)}`),
            try: () => readFile(schemaPath.value, 'utf8'),
          }).pipe(
            Effect.map((schemaText) => ({
              ...bodyWithPrompt,
              response_format: { schema: JSON.parse(schemaText) as unknown, type: 'json_schema' },
            })),
          )
        : bodyWithPrompt

      const result = yield* ApiClient.jsonExtract(auth, body)
      yield* Output.printJson(result)
    }),
).pipe(Command.withDescription('Extract structured data using AI'))
