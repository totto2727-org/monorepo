import { Command } from 'effect/unstable/cli'

import { taskSetNoteCommand } from '#@/cli/task/set/note.ts'
import { taskSetPrsCommand } from '#@/cli/task/set/prs.ts'
import { taskSetStatusCommand } from '#@/cli/task/set/status.ts'

export const taskSetCommand = Command.make('set').pipe(
  Command.withDescription('Set task properties'),
  Command.withSubcommands([taskSetStatusCommand, taskSetNoteCommand, taskSetPrsCommand]),
)
