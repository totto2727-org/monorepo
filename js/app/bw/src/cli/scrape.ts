import { Effect } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { applyWaitUntil, loadConfig, resolveInput } from '#@/lib/config.ts'
import * as Flags from '#@/lib/flags.ts'
import * as ApiClient from '#@/service/api-client.ts'
import * as Auth from '#@/service/auth.ts'
import * as Output from '#@/service/output.ts'

export const scrapeCommand = Command.make(
  'scrape',
  {
    accountId: Flags.accountId,
    apiToken: Flags.apiToken,
    config: Flags.config,
    html: Flags.html,
    selector: Flag.string('selector').pipe(Flag.withDescription('CSS selector to extract')),
    url: Flags.url,
    waitUntil: Flags.waitUntil,
  },
  (flags) =>
    Effect.gen(function* () {
      const auth = yield* Auth.resolve(flags)
      const config = yield* loadConfig(flags.config)
      const baseBody = yield* resolveInput(flags.url, flags.html, config)
      const body = { ...applyWaitUntil(baseBody, flags.waitUntil), elements: [{ selector: flags.selector }] }
      const result = yield* ApiClient.scrape(auth, body)
      yield* Output.printJson(result)
    }),
).pipe(Command.withDescription('Extract elements by CSS selector'))
