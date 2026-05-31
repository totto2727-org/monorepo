import { Command, Flag } from 'effect/unstable/cli'

import { resolveDirAgainstRepoRoot } from '#@/lib/git.ts'

export const rootCommand = Command.make('roadmap').pipe(
  Command.withDescription('Roadmap progress.yaml manager'),
  Command.withSharedFlags({
    dir: Flag.string('dir').pipe(
      Flag.withAlias('d'),
      Flag.withDefault('docs/roadmap'),
      Flag.withDescription('Base directory under the repo root (default: docs/roadmap)'),
    ),
  }),
)

export const resolveDirOrFail = (relativeDir: string) => resolveDirAgainstRepoRoot(relativeDir)
