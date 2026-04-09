import { NodeServices } from '@effect/platform-node'
import { Effect, Layer } from 'effect'
import { Command } from 'effect/unstable/cli'
import { FetchHttpClient } from 'effect/unstable/http'

import { contentCommand } from '#@/cli/content.ts'
import { crawlListCommand } from '#@/cli/crawl/list.ts'
import { crawlResultsCommand } from '#@/cli/crawl/results.ts'
import { crawlStartCommand } from '#@/cli/crawl/start.ts'
import { crawlStatusCommand } from '#@/cli/crawl/status.ts'
import { jsonCommand } from '#@/cli/json.ts'
import { linksCommand } from '#@/cli/links.ts'
import { markdownCommand } from '#@/cli/markdown.ts'
import { pdfCommand } from '#@/cli/pdf.ts'
import { scrapeCommand } from '#@/cli/scrape.ts'
import { screenshotCommand } from '#@/cli/screenshot.ts'
import { snapshotCommand } from '#@/cli/snapshot.ts'

const crawlCommand = Command.make('crawl').pipe(
  Command.withDescription('Manage async crawl jobs'),
  Command.withSubcommands([crawlStartCommand, crawlStatusCommand, crawlResultsCommand, crawlListCommand]),
)

const app = Command.make('bw').pipe(
  Command.withDescription('CLI for Cloudflare Browser Rendering API'),
  Command.withSubcommands([
    contentCommand,
    screenshotCommand,
    pdfCommand,
    markdownCommand,
    snapshotCommand,
    scrapeCommand,
    jsonCommand,
    linksCommand,
    crawlCommand,
  ]),
)

const appLayer = Layer.merge(NodeServices.layer, FetchHttpClient.layer)

const program = app.pipe(Command.run({ version: '0.1.0' }), Effect.provide(appLayer))

Effect.runFork(program)
