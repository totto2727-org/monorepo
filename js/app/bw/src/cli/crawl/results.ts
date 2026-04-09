import { Effect } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import * as Flags from '#@/lib/flags.ts'
import * as ApiClient from '#@/service/api-client.ts'
import * as Auth from '#@/service/auth.ts'
import * as Output from '#@/service/output.ts'

export const crawlResultsCommand = Command.make(
  'results',
  {
    accountId: Flags.accountId,
    apiToken: Flags.apiToken,
    id: Flag.string('id').pipe(Flag.withDescription('Crawl job ID')),
    output: Flags.output,
  },
  (flags) =>
    Effect.gen(function* () {
      const auth = yield* Auth.resolve(flags)
      const result = yield* ApiClient.crawlResults(auth, flags.id)

      if (flags.output._tag === 'Some') {
        yield* Output.writeText(flags.output.value, JSON.stringify(result, null, 2))
        yield* Effect.log(`Results saved to ${flags.output.value}`)
      } else {
        yield* Output.printJson(result)
      }
    }),
).pipe(Command.withDescription('Retrieve crawl results'))
