import { Effect } from 'effect'
import { Command } from 'effect/unstable/cli'

import * as Flags from '#@/lib/flags.ts'
import * as ApiClient from '#@/service/api-client.ts'
import * as Auth from '#@/service/auth.ts'
import * as Output from '#@/service/output.ts'

export const crawlListCommand = Command.make(
  'list',
  {
    accountId: Flags.accountId,
    apiToken: Flags.apiToken,
  },
  (flags) =>
    Effect.gen(function* () {
      const auth = yield* Auth.resolve(flags)
      const result = yield* ApiClient.crawlList(auth)
      yield* Output.printJson(result)
    }),
).pipe(Command.withDescription('List all crawl jobs'))
