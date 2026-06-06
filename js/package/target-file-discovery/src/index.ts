import { Effect, FileSystem, Path, Predicate, String } from 'effect'
import ignore from 'ignore'

const EMPTY_DIRECTORY_ENTRIES: readonly string[] = []

interface IgnoreRuleSet {
  readonly baseDir: string
  readonly filter: (path: string) => boolean
}

const isIgnoredDirectory = (targetPath: string, ignoreRules: readonly IgnoreRuleSet[], path: Path.Path): boolean =>
  ignoreRules.some((ruleSet) => {
    const relative = path.relative(ruleSet.baseDir, targetPath)
    return !ruleSet.filter(`${relative}/`)
  })

const readIgnoreRules = (dir: string): Effect.Effect<IgnoreRuleSet | null, never, FileSystem.FileSystem | Path.Path> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = yield* Path.Path
    const content = yield* fs.readFileString(path.join(dir, '.gitignore')).pipe(Effect.orElseSucceed(() => ''))
    if (String.isEmpty(content.trim())) {
      return null
    }
    return {
      baseDir: dir,
      filter: ignore().add(content).createFilter(),
    }
  })

export const findHomeTargetFile = (
  homeDir: string,
  fileName: string,
): Effect.Effect<string, Error, FileSystem.FileSystem | Path.Path> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = yield* Path.Path
    const targetFile = path.join(homeDir, fileName)

    if (yield* fs.exists(targetFile).pipe(Effect.orElseSucceed(() => false))) {
      return targetFile
    }

    return yield* Effect.fail(new Error(`Could not find home-level file: ${fileName}`))
  })

export const findParentTargetFile = (
  fileName: string,
  topDir: string,
  startDir: string,
): Effect.Effect<string, Error, FileSystem.FileSystem | Path.Path> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = yield* Path.Path
    const boundaryDir = path.resolve(topDir)
    const currentDir = path.resolve(startDir)
    const targetFile = path.join(currentDir, fileName)

    if (yield* fs.exists(targetFile).pipe(Effect.orElseSucceed(() => false))) {
      return targetFile
    }

    if (currentDir === boundaryDir) {
      return yield* Effect.fail(new Error(`Could not find ancestor file: ${fileName}`))
    }

    const parentDir = path.dirname(currentDir)
    if (parentDir === currentDir) {
      return yield* Effect.fail(new Error(`Reached filesystem root before top directory: ${topDir}`))
    }

    return yield* findParentTargetFile(fileName, boundaryDir, parentDir)
  })

const collectRecursiveTargetFilesFrom = (
  dir: string,
  fileName: string,
  inheritedIgnoreRules: readonly IgnoreRuleSet[],
): Effect.Effect<string[], never, FileSystem.FileSystem | Path.Path> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = yield* Path.Path
    const targetFile = path.join(dir, fileName)
    const [localIgnoreRules, hasTargetFile, entries] = yield* Effect.all(
      [
        readIgnoreRules(dir),
        fs.exists(targetFile).pipe(Effect.orElseSucceed(() => false)),
        fs.readDirectory(dir).pipe(Effect.orElseSucceed(() => EMPTY_DIRECTORY_ENTRIES)),
      ],
      { concurrency: 'unbounded' },
    )
    const ignoreRules = localIgnoreRules ? [...inheritedIgnoreRules, localIgnoreRules] : inheritedIgnoreRules
    const currentFiles = hasTargetFile ? [targetFile] : []

    const entryPaths = entries.map((entry) => path.join(dir, entry))
    const statResults = yield* Effect.all(
      entryPaths.map((entryPath) =>
        fs.stat(entryPath).pipe(
          Effect.map((stat) => ({ entryPath, stat })),
          Effect.orElseSucceed(() => null),
        ),
      ),
      { concurrency: 'unbounded' },
    )
    const directoryPaths = statResults
      .filter(Predicate.isNotNullish)
      .filter((result) => result.stat.type === 'Directory')
      .map((result) => result.entryPath)
    const searchableDirectoryPaths = directoryPaths.filter(
      (entryPath) => !isIgnoredDirectory(entryPath, ignoreRules, path),
    )
    const descendantFiles = yield* Effect.all(
      searchableDirectoryPaths.map((entryPath) => collectRecursiveTargetFilesFrom(entryPath, fileName, ignoreRules)),
      { concurrency: 'unbounded' },
    )
    return [...currentFiles, ...descendantFiles.flat()]
  }).pipe(Effect.orElseSucceed((): string[] => []))

export const collectRecursiveTargetFiles = (
  startDir: string,
  fileName: string,
): Effect.Effect<string[], never, FileSystem.FileSystem | Path.Path> =>
  collectRecursiveTargetFilesFrom(startDir, fileName, [])
