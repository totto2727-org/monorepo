import { Command } from 'effect/unstable/cli'

import { milestoneSetNoteCommand } from '#@/cli/milestone/set/note.ts'
import { milestoneSetPrsCommand } from '#@/cli/milestone/set/prs.ts'
import { milestoneSetStatusCommand } from '#@/cli/milestone/set/status.ts'

export const milestoneSetCommand = Command.make('set').pipe(
  Command.withDescription('Set milestone properties'),
  Command.withSubcommands([milestoneSetStatusCommand, milestoneSetNoteCommand, milestoneSetPrsCommand]),
)
