#!/usr/bin/env node

import { NodeRuntime, NodeServices } from '@effect/platform-node'
import { Effect, Option, String } from 'effect'
import { Command, Flag } from 'effect/unstable/cli'

import { buildMarkdown } from './build.ts'
import { formatLintResult, lintMarkdown } from './lint.ts'
import { createMarkdownPreview } from './preview.ts'

const configFlag = Flag.file('config').pipe(
  Flag.withAlias('c'),
  Flag.withDescription('Path to mdts.config.ts'),
  Flag.optional,
)

const commandOptions = (config: Option.Option<string>) => ({
  configFile: Option.getOrUndefined(config),
  root: process.cwd(),
})

const buildCommand = Command.make('build', { config: configFlag }, ({ config }) =>
  Effect.tryPromise(() => buildMarkdown(commandOptions(config))),
).pipe(Command.withDescription('Build Markdown documents'))

const lintCommand = Command.make('lint', { config: configFlag }, ({ config }) =>
  Effect.tryPromise(async () => {
    const result = await lintMarkdown(commandOptions(config))
    const output = formatLintResult(result)
    if (String.isNonEmpty(output)) {
      process.stderr.write(`${output}\n`)
    }
    if (result.errorCount > 0) {
      process.exitCode = 1
    }
  }),
).pipe(Command.withDescription('Lint generated Markdown documents'))

const previewCommand = Command.make('preview', { config: configFlag }, ({ config }) =>
  Effect.acquireRelease(
    Effect.tryPromise(async () => {
      const server = await createMarkdownPreview(commandOptions(config))
      await server.listen()
      server.printUrls()
      server.bindCLIShortcuts({ print: true })
      return server
    }),
    (server) => Effect.promise(() => server.close()),
  ).pipe(Effect.andThen(Effect.never), Effect.scoped),
).pipe(Command.withDescription('Preview Markdown documents'))

const mdtsCommand = Command.make('mdts').pipe(
  Command.withDescription('Build and preview Markdown documents'),
  Command.withSubcommands([buildCommand, lintCommand, previewCommand]),
)

const program = Command.run(mdtsCommand, { version: '0.0.0' }).pipe(Effect.provide(NodeServices.layer))

// oxlint-disable-next-line rules/no-effect-runtime-run -- CLI entrypoint executes the top-level mdts workflow once.
NodeRuntime.runMain(program)
