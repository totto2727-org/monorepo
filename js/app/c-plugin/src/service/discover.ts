import { Effect, FileSystem, Path } from 'effect'

import { findNearestAgentsDir, getLockFilePath } from '#@/lib/paths.ts'

const SKIP_DIRS = new Set(['.agents', '.git', 'node_modules'])

const collectFrom = (dir: string, results: string[]): Effect.Effect<void, never, FileSystem.FileSystem | Path.Path> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = yield* Path.Path
    const agentsDir = path.join(dir, '.agents')
    const hasLockFile = yield* fs.exists(getLockFilePath(agentsDir)).pipe(Effect.orElseSucceed(() => false))
    if (hasLockFile) {
      results.push(agentsDir)
    }

    const entries = yield* fs.readDirectory(dir).pipe(Effect.orElseSucceed(() => [] as readonly string[]))
    for (const entry of entries) {
      if (SKIP_DIRS.has(entry)) {
        continue
      }
      const entryPath = path.join(dir, entry)
      const stat = yield* fs.stat(entryPath).pipe(Effect.orElseSucceed(() => null))
      if (stat?.type === 'Directory') {
        yield* collectFrom(entryPath, results)
      }
    }
  })

export const collectAgentsDirs = (
  startDir: string,
): Effect.Effect<string[], never, FileSystem.FileSystem | Path.Path> =>
  Effect.gen(function* () {
    const results: string[] = []
    yield* collectFrom(startDir, results)
    return results
  }).pipe(Effect.orElseSucceed((): string[] => []))

export const resolveAgentsDirs = (
  recursive: boolean,
): Effect.Effect<string[], never, FileSystem.FileSystem | Path.Path> =>
  Effect.gen(function* () {
    const path = yield* Path.Path
    const nearest = yield* findNearestAgentsDir()
    if (!recursive) {
      return [nearest]
    }
    const startDir = path.dirname(nearest)
    const all = yield* collectAgentsDirs(startDir)
    return all
  }).pipe(Effect.orElseSucceed((): string[] => []))
