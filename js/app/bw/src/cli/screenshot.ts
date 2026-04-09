import { Effect } from 'effect'
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
      let body = yield* resolveInput(flags.url, flags.html, config)
      body = applyWaitUntil(body, flags.waitUntil)
      if (flags.fullPage) {
        body = { ...body, screenshotOptions: { fullPage: true } }
      }
      if (flags.width._tag === 'Some' || flags.height._tag === 'Some') {
        const existing = body['viewport']
        const viewportBase = typeof existing === 'object' && existing !== null ? existing : {}
        body = {
          ...body,
          viewport: {
            ...viewportBase,
            ...(flags.width._tag === 'Some' ? { width: flags.width.value } : {}),
            ...(flags.height._tag === 'Some' ? { height: flags.height.value } : {}),
          },
        }
      }
      const data = yield* ApiClient.screenshot(auth, body)
      yield* Output.writeFile(flags.output, data)
      yield* Effect.log(`Screenshot saved to ${flags.output}`)
    }),
).pipe(Command.withDescription('Capture a screenshot of a URL'))
