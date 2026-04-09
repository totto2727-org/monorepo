import { Effect } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import * as Flags from '#@/lib/flags.ts'
import * as ApiClient from '#@/service/api-client.ts'
import * as Auth from '#@/service/auth.ts'
import * as Output from '#@/service/output.ts'

export const crawlStatusCommand = Command.make(
  'status',
  {
    accountId: Flags.accountId,
    apiToken: Flags.apiToken,
    id: Flag.string('id').pipe(Flag.withDescription('Crawl job ID')),
  },
  (flags) =>
    Effect.gen(function* () {
      const auth = yield* Auth.resolve(flags)
      const result = yield* ApiClient.crawlStatus(auth, flags.id)
      yield* Output.printJson(result)
    }),
).pipe(Command.withDescription('Check crawl job status'))
