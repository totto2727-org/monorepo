#!/usr/bin/env node
import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { Command } from 'effect/unstable/cli'

import { translateCommand } from '#@/cli/translate.ts'

const program = translateCommand.pipe(Command.run({ version: '0.1.0' }), Effect.provide(NodeServices.layer))

Effect.runFork(program)
