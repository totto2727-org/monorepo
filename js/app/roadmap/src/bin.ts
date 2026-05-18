#!/usr/bin/env node
import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { Command } from 'effect/unstable/cli'

import { newCommand } from '#@/cli/new.ts'

const app = Command.make('roadmap').pipe(
  Command.withDescription('Roadmap progress.yaml manager'),
  Command.withSubcommands([newCommand]),
)

const program = app.pipe(Command.run({ version: '0.1.0' }), Effect.provide(NodeServices.layer))

Effect.runFork(program)
