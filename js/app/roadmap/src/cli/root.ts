import { Command, Flag } from 'effect/unstable/cli'

export const rootCommand = Command.make('roadmap').pipe(
  Command.withDescription('Roadmap progress.yaml manager'),
  Command.withSharedFlags({
    dir: Flag.string('dir').pipe(
      Flag.withAlias('d'),
      Flag.withDefault('docs/roadmap'),
      Flag.withDescription('Base directory under which <roadmap-id>/progress.yaml lives'),
    ),
  }),
)
