import { readFile } from 'node:fs/promises'

import { Effect } from 'effect'
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
      let body = yield* resolveInput(flags.url, flags.html, config)
      body = applyWaitUntil(body, flags.waitUntil)
      body = { ...body, prompt: flags.prompt }

      if (flags.schema._tag === 'Some') {
        const schemaPath = flags.schema.value
        const schemaText = yield* Effect.tryPromise({
          catch: (error) =>
            new Error(`Failed to read schema file: ${error instanceof Error ? error.message : String(error)}`),
          try: () => readFile(schemaPath, 'utf8'),
        })
        const schemaJson: unknown = JSON.parse(schemaText)
        body = {
          ...body,
          response_format: { schema: schemaJson, type: 'json_schema' },
        }
      }

      const result = yield* ApiClient.jsonExtract(auth, body)
      yield* Output.printJson(result)
    }),
).pipe(Command.withDescription('Extract structured data using AI'))
