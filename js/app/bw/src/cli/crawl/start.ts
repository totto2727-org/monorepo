import { Effect } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { applyWaitUntil, loadConfig, resolveInput } from '#@/lib/config.ts'
import * as Flags from '#@/lib/flags.ts'
import * as ApiClient from '#@/service/api-client.ts'
import * as Auth from '#@/service/auth.ts'
import * as Output from '#@/service/output.ts'

export const crawlStartCommand = Command.make(
  'start',
  {
    accountId: Flags.accountId,
    apiToken: Flags.apiToken,
    config: Flags.config,
    depth: Flag.integer('depth').pipe(Flag.optional, Flag.withDescription('Max link depth')),
    format: Flag.string('format').pipe(Flag.optional, Flag.withDescription('Output formats: html, markdown, json')),
    html: Flags.html,
    limit: Flag.integer('limit').pipe(Flag.optional, Flag.withDescription('Max pages to crawl')),
    output: Flags.output,
    url: Flags.url,
    wait: Flag.boolean('wait').pipe(Flag.withDescription('Wait for crawl to complete')),
    waitUntil: Flags.waitUntil,
  },
  (flags) =>
    Effect.gen(function* () {
      const auth = yield* Auth.resolve(flags)
      const config = yield* loadConfig(flags.config)
      let body = yield* resolveInput(flags.url, flags.html, config)
      body = applyWaitUntil(body, flags.waitUntil)
      if (flags.limit._tag === 'Some') {
        body = { ...body, limit: flags.limit.value }
      }
      if (flags.depth._tag === 'Some') {
        body = { ...body, depth: flags.depth.value }
      }
      if (flags.format._tag === 'Some') {
        body = { ...body, formats: flags.format.value.split(',') }
      }

      const crawlId = yield* ApiClient.crawlStart(auth, body)
      yield* Effect.log(`Crawl started: ${crawlId}`)

      if (!flags.wait) {
        yield* Output.printText(crawlId)
        return
      }

      yield* Effect.log('Waiting for crawl to complete...')

      let status = yield* ApiClient.crawlStatus(auth, crawlId)
      while (status.status === 'running') {
        yield* Effect.sleep('3 seconds')
        status = yield* ApiClient.crawlStatus(auth, crawlId)
        yield* Effect.log(`Status: ${status.status} (${status.finished ?? 0}/${status.total ?? '?'} pages)`)
      }

      yield* Effect.log(`Crawl ${status.status}: ${status.finished ?? 0} pages`)

      if (flags.output._tag === 'Some') {
        const results = yield* ApiClient.crawlResults(auth, crawlId)
        yield* Output.writeText(flags.output.value, JSON.stringify(results, null, 2))
        yield* Effect.log(`Results saved to ${flags.output.value}`)
      }
    }),
).pipe(Command.withDescription('Start an async crawl job'))
