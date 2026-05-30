import * as Fs from 'node:fs/promises'

import { Effect } from 'effect'

import { getCacheDir, getGitHubCloneUrl, getRepoCacheDir, getSkillsDir, resolveLocalPath } from '#@/lib/paths.ts'
import * as Git from '#@/service/git.ts'

export const ensureDirs = (agentsDir: string, projectRoot: string): Effect.Effect<void> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: async () => {
      await Fs.mkdir(getCacheDir(projectRoot), { recursive: true })
      await Fs.mkdir(getSkillsDir(agentsDir), { recursive: true })
    },
  }).pipe(Effect.ignore)

export const ensureRepo = (projectRoot: string, source: string): Effect.Effect<string, Git.GitError> => {
  const repoDir = getRepoCacheDir(projectRoot, source)
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

export const removeRepo = (projectRoot: string, source: string): Effect.Effect<void> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: () => Fs.rm(getRepoCacheDir(projectRoot, source), { force: true, recursive: true }),
  }).pipe(Effect.ignore)

export const ensureLocalPath = (spec: string, agentsRoot: string): Effect.Effect<string, Error> =>
  Effect.tryPromise({
    catch: () => new Error(`Local path does not exist: ${spec}`),
    try: async () => {
      const resolved = resolveLocalPath(spec, agentsRoot)
      await Fs.access(resolved)
      return resolved
    },
  })
