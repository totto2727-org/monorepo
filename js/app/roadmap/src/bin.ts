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

import pkg from '../package.json' with { type: 'json' }

const app = rootCommand.pipe(
  Command.withSubcommands([newCommand, lsCommand, statusCommand, setCommand, milestoneCommand, serveCommand]),
)

const program = app.pipe(Command.run({ version: pkg.version }), Effect.provide(NodeServices.layer))

Effect.runFork(program)
