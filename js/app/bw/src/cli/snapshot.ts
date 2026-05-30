import { Effect, FileSystem, Path } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { applyWaitUntil, loadConfig, resolveInput } from '#@/lib/config.ts'
import * as Flags from '#@/lib/flags.ts'
import * as ApiClient from '#@/service/api-client.ts'
import * as Auth from '#@/service/auth.ts'
import * as Output from '#@/service/output.ts'

export const snapshotCommand = Command.make(
  'snapshot',
  {
    accountId: Flags.accountId,
    apiToken: Flags.apiToken,
    config: Flags.config,
    fullPage: Flag.boolean('full-page').pipe(Flag.withDescription('Capture entire page')),
    html: Flags.html,
    output: Flags.requiredOutput,
    url: Flags.url,
    waitUntil: Flags.waitUntil,
  },
  (flags) =>
    Effect.gen(function* () {
      const auth = yield* Auth.resolve(flags)
      const config = yield* loadConfig(flags.config)
      const baseBody = yield* resolveInput(flags.url, flags.html, config)
      const bodyWithWait = applyWaitUntil(baseBody, flags.waitUntil)
      const body = flags.fullPage ? { ...bodyWithWait, screenshotOptions: { fullPage: true } } : bodyWithWait
      const result = yield* ApiClient.snapshot(auth, body)

      const base = flags.output.replace(/\/$/u, '')
      const path = yield* Path.Path
      const name = path.basename(base)
      const dir = base

      const fs = yield* FileSystem.FileSystem
      yield* fs
        .makeDirectory(dir, { recursive: true })
        .pipe(Effect.mapError((error) => new Output.OutputError({ error, path: dir })))

      const screenshotBuf = Buffer.from(result.screenshot, 'base64')
      yield* Effect.all([
        Output.writeFile(path.join(dir, `${name}.png`), new Uint8Array(screenshotBuf)),
        Output.writeText(path.join(dir, `${name}.html`), result.content),
      ])
      yield* Effect.log(`Snapshot saved to ${dir}/`)
    }),
).pipe(Command.withDescription('Capture both HTML and screenshot from a URL'))
