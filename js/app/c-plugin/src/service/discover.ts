import { collectRecursiveTargetFiles, findParentTargetFile } from '@package/target-file-discovery'
import type { FileSystem } from 'effect'
import { Effect, Path } from 'effect'

import { LOCK_FILE_NAME } from '#@/lib/paths.ts'

interface ResolveAgentsDirsOptions {
  readonly searchTopDir: string
}

const toAgentsDir = (lockFilePath: string, path: Path.Path): string => path.join(path.dirname(lockFilePath), '.agents')

export const collectAgentsDirs = (
  startDir: string,
): Effect.Effect<string[], never, FileSystem.FileSystem | Path.Path> =>
  Effect.gen(function* () {
    const path = yield* Path.Path
    const collectLockFiles: Effect.Effect<string[], never, FileSystem.FileSystem | Path.Path> =
      collectRecursiveTargetFiles(startDir, LOCK_FILE_NAME)
    const lockFiles = yield* collectLockFiles
    return lockFiles.map((lockFile) => toAgentsDir(lockFile, path))
  }).pipe(Effect.orElseSucceed((): string[] => []))

export const resolveAgentsDirs = (
  recursive: boolean,
  searchStartDir: string,
  options: ResolveAgentsDirsOptions,
): Effect.Effect<string[], never, FileSystem.FileSystem | Path.Path> =>
  Effect.gen(function* () {
    const path = yield* Path.Path
    const findNearestLockFile: Effect.Effect<string, Error, FileSystem.FileSystem | Path.Path> = findParentTargetFile(
      LOCK_FILE_NAME,
      options.searchTopDir,
      searchStartDir,
    )
    const nearestLockFile = yield* findNearestLockFile
    const nearest = toAgentsDir(nearestLockFile, path)
    if (!recursive) {
      return [nearest]
    }
    const recursiveStartDir = path.dirname(nearestLockFile)
    const all = yield* collectAgentsDirs(recursiveStartDir)
    return all
  }).pipe(Effect.orElseSucceed((): string[] => []))
