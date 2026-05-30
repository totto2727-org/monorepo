import { Effect, FileSystem, Path } from 'effect'

import { expandHomePath, getSkillsDir } from '#@/lib/paths.ts'

const createLinkInDir = (
  dir: string,
  skillName: string,
  targetPath: string,
): Effect.Effect<void, never, FileSystem.FileSystem | Path.Path> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = yield* Path.Path
    yield* fs.makeDirectory(dir, { recursive: true }).pipe(Effect.ignore)
    const linkPath = path.join(dir, skillName)
    const relativePath = path.relative(dir, targetPath)
    yield* fs.remove(linkPath, { force: true }).pipe(Effect.ignore)
    yield* fs.symlink(relativePath, linkPath).pipe(Effect.ignore)
  })

const removeLinkInDir = (
  dir: string,
  skillName: string,
): Effect.Effect<void, never, FileSystem.FileSystem | Path.Path> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = yield* Path.Path
    const linkPath = path.join(dir, skillName)
    yield* fs.remove(linkPath, { force: true }).pipe(Effect.ignore)
  })

const getAllDirs = (agentsDir: string, skillDirs: readonly string[]): string[] => {
  const primary = getSkillsDir(agentsDir)
  return [primary, ...skillDirs.map(expandHomePath)]
}

export const createSkillLink = (
  agentsDir: string,
  skillDirs: readonly string[],
  skillName: string,
  targetPath: string,
): Effect.Effect<void, never, FileSystem.FileSystem | Path.Path> =>
  Effect.all(
    getAllDirs(agentsDir, skillDirs).map((dir) => createLinkInDir(dir, skillName, targetPath)),
    { concurrency: 'unbounded' },
  ).pipe(Effect.asVoid)

export const removeSkillLink = (
  agentsDir: string,
  skillDirs: readonly string[],
  skillName: string,
): Effect.Effect<void, never, FileSystem.FileSystem | Path.Path> =>
  Effect.all(
    getAllDirs(agentsDir, skillDirs).map((dir) => removeLinkInDir(dir, skillName)),
    { concurrency: 'unbounded' },
  ).pipe(Effect.asVoid)

export const removeSkillLinkFromDirs = (
  dirs: readonly string[],
  skillName: string,
): Effect.Effect<void, never, FileSystem.FileSystem | Path.Path> =>
  Effect.all(
    dirs.map((dir) => removeLinkInDir(expandHomePath(dir), skillName)),
    { concurrency: 'unbounded' },
  ).pipe(Effect.asVoid)

export const listSkillLinks = (
  agentsDir: string,
): Effect.Effect<readonly string[], never, FileSystem.FileSystem | Path.Path> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = yield* Path.Path
    const skillsDir = getSkillsDir(agentsDir)
    const entries = yield* fs.readDirectory(skillsDir).pipe(Effect.orElseSucceed(() => [] as readonly string[]))
    const links: string[] = []
    for (const entry of entries) {
      const fullPath = path.join(skillsDir, entry)
      const isLink = yield* fs.readLink(fullPath).pipe(
        Effect.as(true),
        Effect.orElseSucceed(() => false),
      )
      if (isLink) {
        links.push(entry)
      }
    }
    return links
  }).pipe(Effect.orElseSucceed((): string[] => []))
