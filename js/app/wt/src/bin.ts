#!/usr/bin/env node
import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { Command } from 'effect/unstable/cli'

import { cleanupCommand } from '#@/cli/cleanup.ts'
import { lsCommand } from '#@/cli/ls.ts'

import pkg from '../package.json' with { type: 'json' }

const app = Command.make('wt').pipe(
  Command.withDescription('Git worktree manager'),
  Command.withSubcommands([lsCommand, cleanupCommand]),
)

const program = app.pipe(Command.run({ version: pkg.version }), Effect.provide(NodeServices.layer))

// oxlint-disable-next-line rules/no-effect-runtime-run -- CLI executable entrypoint owns process-level Effect runtime execution.
Effect.runFork(program)
