import { Effect, FileSystem } from 'effect'

import { getCacheDir, getGitHubCloneUrl, getRepoCacheDir, getSkillsDir, resolveLocalPath } from '#@/lib/paths.ts'
import * as Git from '#@/service/git.ts'

export const ensureDirs = (agentsDir: string, projectRoot: string): Effect.Effect<void, never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    yield* fs.makeDirectory(getCacheDir(projectRoot), { recursive: true }).pipe(Effect.ignore)
    yield* fs.makeDirectory(getSkillsDir(agentsDir), { recursive: true }).pipe(Effect.ignore)
  })

export const ensureRepo = (
  projectRoot: string,
  source: string,
): Effect.Effect<string, Git.GitError, FileSystem.FileSystem> => {
  const repoDir = getRepoCacheDir(projectRoot, source)
  return Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const exists = yield* fs.exists(repoDir).pipe(Effect.orElseSucceed(() => false))
    if (exists) {
      return repoDir
    }
    return yield* Effect.fail(new Git.GitError({ command: 'access', message: 'not found' }))
  }).pipe(
    Effect.catchTag('GitError', () => {
      const url = getGitHubCloneUrl(source)
      return Git.clone(url, repoDir).pipe(Effect.map(() => repoDir))
    }),
  )
}

export const removeRepo = (projectRoot: string, source: string): Effect.Effect<void, never, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    yield* fs.remove(getRepoCacheDir(projectRoot, source), { recursive: true }).pipe(Effect.ignore)
  })

export const ensureLocalPath = (
  spec: string,
  agentsRoot: string,
): Effect.Effect<string, Error, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const resolved = resolveLocalPath(spec, agentsRoot)
    const fs = yield* FileSystem.FileSystem
    const exists = yield* fs.exists(resolved).pipe(Effect.orElseSucceed(() => false))
    if (!exists) {
      return yield* Effect.fail(new Error(`Local path does not exist: ${spec}`))
    }
    return resolved
  })
