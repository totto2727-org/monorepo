#!/usr/bin/env node
import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { Command } from 'effect/unstable/cli'

import { lsCommand } from '#@/cli/ls.ts'
import { milestoneCommand } from '#@/cli/milestone.ts'
import { newCommand } from '#@/cli/new.ts'
import { rootCommand } from '#@/cli/root.ts'
import { serveCommand } from '#@/cli/serve.ts'
import { setCommand } from '#@/cli/set.ts'
import { statusCommand } from '#@/cli/status.ts'
import { taskCommand } from '#@/cli/task.ts'

import pkg from '../package.json' with { type: 'json' }

const handleFailure = (failureCause: unknown): Effect.Effect<void> =>
  Effect.gen(function* () {
    yield* Effect.logError(failureCause)
    yield* Effect.sync(() => {
      process.exitCode = 1
    })
  })

const app = rootCommand.pipe(
  Command.withSubcommands([
    newCommand,
    lsCommand,
    statusCommand,
    setCommand,
    milestoneCommand,
    taskCommand,
    serveCommand,
  ]),
)

const program = app.pipe(
  Command.run({ version: pkg.version }),
  Effect.catchCause(handleFailure),
  Effect.provide(NodeServices.layer),
)

// oxlint-disable-next-line rules/no-effect-runtime-run -- CLI executable entrypoint owns process-level Effect runtime execution.
Effect.runFork(program)
