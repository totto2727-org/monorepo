import { Effect, Option } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { applyWaitUntil, loadConfig, resolveInput } from '#@/lib/config.ts'
import * as Flags from '#@/lib/flags.ts'
import * as ApiClient from '#@/service/api-client.ts'
import * as Auth from '#@/service/auth.ts'
import * as Output from '#@/service/output.ts'

export const pdfCommand = Command.make(
  'pdf',
  {
    accountId: Flags.accountId,
    apiToken: Flags.apiToken,
    config: Flags.config,
    format: Flag.string('format').pipe(Flag.optional, Flag.withDescription('Page format: a4, a5, letter, etc.')),
    html: Flags.html,
    landscape: Flag.boolean('landscape').pipe(Flag.withDescription('Landscape orientation')),
    output: Flags.requiredOutput,
    url: Flags.url,
    waitUntil: Flags.waitUntil,
  },
  (flags) =>
    Effect.gen(function* () {
      const auth = yield* Auth.resolve(flags)
      const config = yield* loadConfig(flags.config)
      const baseBody = yield* resolveInput(flags.url, flags.html, config)
      const pdfOptions = {
        ...(flags.landscape ? { landscape: true } : {}),
        ...(Option.isSome(flags.format) ? { format: flags.format.value } : {}),
      }
      const body = {
        ...applyWaitUntil(baseBody, flags.waitUntil),
        ...(Object.keys(pdfOptions).length > 0 ? { pdfOptions } : {}),
      }
      const data = yield* ApiClient.pdf(auth, body)
      yield* Output.writeFile(flags.output, data)
      yield* Effect.log(`PDF saved to ${flags.output}`)
    }),
).pipe(Command.withDescription('Generate a PDF from a URL'))
