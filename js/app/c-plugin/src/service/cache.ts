import * as Fs from 'node:fs/promises'

import { Effect } from 'effect'

import { getCacheDir, getGitHubCloneUrl, getRepoCacheDir, getSkillsDir } from '#@/lib/paths.ts'
import * as Git from '#@/service/git.ts'

export const ensureDirs = (agentsDir: string): Effect.Effect<void> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: async () => {
      await Fs.mkdir(getCacheDir(agentsDir), { recursive: true })
      await Fs.mkdir(getSkillsDir(agentsDir), { recursive: true })
    },
  }).pipe(Effect.ignore)

export const ensureRepo = (agentsDir: string, source: string): Effect.Effect<string, Git.GitError> => {
  const repoDir = getRepoCacheDir(agentsDir, source)
  return Effect.tryPromise({
    catch: () => new Git.GitError({ command: 'access', message: 'not found' }),
    try: () => Fs.access(repoDir),
  }).pipe(
    Effect.map(() => repoDir),
    Effect.catchTag('GitError', () => {
      const url = getGitHubCloneUrl(source)
      return Git.clone(url, repoDir).pipe(Effect.map(() => repoDir))
    }),
  )
}

export const removeRepo = (agentsDir: string, source: string): Effect.Effect<void> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: () => Fs.rm(getRepoCacheDir(agentsDir, source), { force: true, recursive: true }),
  }).pipe(Effect.ignore)
