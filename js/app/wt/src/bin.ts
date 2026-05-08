#!/usr/bin/env node
import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { Command } from 'effect/unstable/cli'

import { cleanupCommand } from '#@/cli/cleanup.ts'
import { lsCommand } from '#@/cli/ls.ts'

const app = Command.make('wt').pipe(
  Command.withDescription('Git worktree manager'),
  Command.withSubcommands([lsCommand, cleanupCommand]),
)

const program = app.pipe(Command.run({ version: '0.1.0' }), Effect.provide(NodeServices.layer))

Effect.runFork(program)
