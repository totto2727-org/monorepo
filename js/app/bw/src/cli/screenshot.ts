import { Effect, Option, Predicate } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { applyWaitUntil, loadConfig, resolveInput } from '#@/lib/config.ts'
import * as Flags from '#@/lib/flags.ts'
import * as ApiClient from '#@/service/api-client.ts'
import * as Auth from '#@/service/auth.ts'
import * as Output from '#@/service/output.ts'

export const screenshotCommand = Command.make(
  'screenshot',
  {
    accountId: Flags.accountId,
    apiToken: Flags.apiToken,
    config: Flags.config,
    fullPage: Flag.boolean('full-page').pipe(Flag.withDescription('Capture entire page')),
    height: Flag.integer('height').pipe(Flag.optional, Flag.withDescription('Viewport height')),
    html: Flags.html,
    output: Flags.requiredOutput,
    url: Flags.url,
    waitUntil: Flags.waitUntil,
    width: Flag.integer('width').pipe(Flag.optional, Flag.withDescription('Viewport width')),
  },
  (flags) =>
    Effect.gen(function* () {
      const auth = yield* Auth.resolve(flags)
      const config = yield* loadConfig(flags.config)
      const baseBody = yield* resolveInput(flags.url, flags.html, config)
      const bodyWithWait = applyWaitUntil(baseBody, flags.waitUntil)
      const bodyWithFullPage = flags.fullPage
        ? { ...bodyWithWait, screenshotOptions: { fullPage: true } }
        : bodyWithWait
      const body =
        Option.isSome(flags.width) || Option.isSome(flags.height)
          ? {
              ...bodyWithFullPage,
              viewport: {
                ...(Predicate.isObject(bodyWithFullPage['viewport']) ? bodyWithFullPage['viewport'] : {}),
                ...(Option.isSome(flags.width) ? { width: flags.width.value } : {}),
                ...(Option.isSome(flags.height) ? { height: flags.height.value } : {}),
              },
            }
          : bodyWithFullPage
      const data = yield* ApiClient.screenshot(auth, body)
      yield* Output.writeFile(flags.output, data)
      yield* Effect.log(`Screenshot saved to ${flags.output}`)
    }),
).pipe(Command.withDescription('Capture a screenshot of a URL'))
