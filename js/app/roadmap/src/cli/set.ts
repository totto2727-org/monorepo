import { Command } from 'effect/unstable/cli'

import { setPrsCommand } from '#@/cli/set/prs.ts'
import { setStatusCommand } from '#@/cli/set/status.ts'

export const setCommand = Command.make('set').pipe(
  Command.withDescription('Set roadmap properties'),
  Command.withSubcommands([setStatusCommand, setPrsCommand]),
)
