import { Command } from 'effect/unstable/cli'

import { setStatusCommand } from '#@/cli/set/status.ts'

export const setCommand = Command.make('set').pipe(
  Command.withDescription('Set roadmap properties'),
  Command.withSubcommands([setStatusCommand]),
)
