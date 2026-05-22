#!/usr/bin/env node
import { NodeServices } from '@effect/platform-node'
import { Effect } from 'effect'
import { Command } from 'effect/unstable/cli'

import { translateCommand } from '#@/cli/translate.ts'

import pkg from '../package.json' with { type: 'json' }

const program = translateCommand.pipe(Command.run({ version: pkg.version }), Effect.provide(NodeServices.layer))

Effect.runFork(program)
