#!/usr/bin/env node
import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { Command } from 'effect/unstable/cli'

import { lsCommand } from '#@/cli/ls.ts'
import { milestoneCommand } from '#@/cli/milestone.ts'
import { newCommand } from '#@/cli/new.ts'
import { rootCommand } from '#@/cli/root.ts'
import { setCommand } from '#@/cli/set.ts'
import { statusCommand } from '#@/cli/status.ts'

const app = rootCommand.pipe(
  Command.withSubcommands([newCommand, lsCommand, statusCommand, setCommand, milestoneCommand]),
)

const program = app.pipe(Command.run({ version: '0.1.0' }), Effect.provide(NodeServices.layer))

Effect.runFork(program)
