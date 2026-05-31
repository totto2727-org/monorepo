import { Command } from 'effect/unstable/cli'

import { taskLsCommand } from '#@/cli/task/ls.ts'
import { taskNewCommand } from '#@/cli/task/new.ts'
import { taskSetCommand } from '#@/cli/task/set.ts'
import { taskStatusCommand } from '#@/cli/task/status.ts'

export const taskCommand = Command.make('task').pipe(
  Command.withDescription('Manage tasks under a milestone (PR-sized breakdown)'),
  Command.withSubcommands([taskNewCommand, taskLsCommand, taskStatusCommand, taskSetCommand]),
)
