import { Effect } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { applyWaitUntil, loadConfig, resolveInput } from '#@/lib/config.ts'
import * as Flags from '#@/lib/flags.ts'
import * as ApiClient from '#@/service/api-client.ts'
import * as Auth from '#@/service/auth.ts'
import * as Output from '#@/service/output.ts'

export const linksCommand = Command.make(
  'links',
  {
    accountId: Flags.accountId,
    apiToken: Flags.apiToken,
    config: Flags.config,
    html: Flags.html,
    internalOnly: Flag.boolean('internal-only').pipe(Flag.withDescription('Only same-domain links')),
    url: Flags.url,
    visibleOnly: Flag.boolean('visible-only').pipe(Flag.withDescription('Only visible links')),
    waitUntil: Flags.waitUntil,
  },
  (flags) =>
    Effect.gen(function* () {
      const auth = yield* Auth.resolve(flags)
      const config = yield* loadConfig(flags.config)
      let body = yield* resolveInput(flags.url, flags.html, config)
      body = applyWaitUntil(body, flags.waitUntil)
      if (flags.visibleOnly) {
        body = { ...body, visibleLinksOnly: true }
      }
      if (flags.internalOnly) {
        body = { ...body, excludeExternalLinks: true }
      }
      const result = yield* ApiClient.links(auth, body)
      yield* Output.printJson(result)
    }),
).pipe(Command.withDescription('Retrieve all links from a URL'))
