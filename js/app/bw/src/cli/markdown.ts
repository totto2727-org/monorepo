import { Effect } from 'effect'
import { Command } from 'effect/unstable/cli'

import { applyWaitUntil, loadConfig, resolveInput } from '#@/lib/config.ts'
import * as Flags from '#@/lib/flags.ts'
import * as ApiClient from '#@/service/api-client.ts'
import * as Auth from '#@/service/auth.ts'
import * as Output from '#@/service/output.ts'

export const markdownCommand = Command.make(
  'markdown',
  {
    accountId: Flags.accountId,
    apiToken: Flags.apiToken,
    config: Flags.config,
    html: Flags.html,
    output: Flags.output,
    url: Flags.url,
    waitUntil: Flags.waitUntil,
  },
  (flags) =>
    Effect.gen(function* () {
      const auth = yield* Auth.resolve(flags)
      const config = yield* loadConfig(flags.config)
      const body = yield* resolveInput(flags.url, flags.html, config)
      const result = yield* ApiClient.markdown(auth, applyWaitUntil(body, flags.waitUntil))

      if (flags.output._tag === 'Some') {
        yield* Output.writeText(flags.output.value, result)
        yield* Effect.log(`Written to ${flags.output.value}`)
      } else {
        yield* Output.printText(result)
      }
    }),
).pipe(Command.withDescription('Extract markdown from a URL'))
