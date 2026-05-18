import { Command } from 'effect/unstable/cli'

import { milestoneLsCommand } from '#@/cli/milestone/ls.ts'
import { milestoneNewCommand } from '#@/cli/milestone/new.ts'
import { milestoneStatusCommand } from '#@/cli/milestone/status.ts'

export const milestoneCommand = Command.make('milestone').pipe(
  Command.withDescription('Manage milestones under a roadmap'),
  Command.withSubcommands([milestoneNewCommand, milestoneLsCommand, milestoneStatusCommand]),
)
