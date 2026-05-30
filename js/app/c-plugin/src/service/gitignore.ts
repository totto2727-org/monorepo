import { Effect, FileSystem } from 'effect'

import { getGitIgnorePath } from '#@/lib/paths.ts'

const CONTENT = `skills/\n.gitignore\n`

export const write = (agentsDir: string): Effect.Effect<void, never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    yield* fs.writeFileString(getGitIgnorePath(agentsDir), CONTENT).pipe(Effect.ignore)
  })
