import * as Fs from 'node:fs/promises'

import { Effect } from 'effect'

import { getGitIgnorePath } from '#@/lib/paths.ts'

const CONTENT = `.cache/\nskills/\n.gitignore\n`

export const write = (agentsDir: string): Effect.Effect<void> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: () => Fs.writeFile(getGitIgnorePath(agentsDir), CONTENT, 'utf-8'),
  }).pipe(Effect.ignore)
