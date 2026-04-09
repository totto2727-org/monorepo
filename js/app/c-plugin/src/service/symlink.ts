import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { Effect } from 'effect'

import { getSkillsDir } from '#@/lib/paths.ts'

const createLinkInDir = (dir: string, skillName: string, targetPath: string): Effect.Effect<void> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: async () => {
      await Fs.mkdir(dir, { recursive: true })
      const linkPath = NodePath.join(dir, skillName)
      const relativePath = NodePath.relative(dir, targetPath)
      try {
        await Fs.unlink(linkPath)
      } catch {
        // ignore if not exists
      }
      await Fs.symlink(relativePath, linkPath)
    },
  }).pipe(Effect.ignore)

const removeLinkInDir = (dir: string, skillName: string): Effect.Effect<void> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: async () => {
      const linkPath = NodePath.join(dir, skillName)
      await Fs.unlink(linkPath)
    },
  }).pipe(Effect.ignore)

const getAllDirs = (agentsDir: string, skillDirs: readonly string[]): string[] => {
  const primary = getSkillsDir(agentsDir)
  return [primary, ...skillDirs]
}

export const createSkillLink = (
  agentsDir: string,
  skillDirs: readonly string[],
  skillName: string,
  targetPath: string,
): Effect.Effect<void> =>
  Effect.all(
    getAllDirs(agentsDir, skillDirs).map((dir) => createLinkInDir(dir, skillName, targetPath)),
    { concurrency: 'unbounded' },
  ).pipe(Effect.asVoid)

export const removeSkillLink = (
  agentsDir: string,
  skillDirs: readonly string[],
  skillName: string,
): Effect.Effect<void> =>
  Effect.all(
    getAllDirs(agentsDir, skillDirs).map((dir) => removeLinkInDir(dir, skillName)),
    { concurrency: 'unbounded' },
  ).pipe(Effect.asVoid)

export const removeSkillLinkFromDirs = (dirs: readonly string[], skillName: string): Effect.Effect<void> =>
  Effect.all(
    dirs.map((dir) => removeLinkInDir(dir, skillName)),
    { concurrency: 'unbounded' },
  ).pipe(Effect.asVoid)

export const listSkillLinks = (agentsDir: string): Effect.Effect<readonly string[]> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: async () => {
      const skillsDir = getSkillsDir(agentsDir)
      const entries = await Fs.readdir(skillsDir)
      const links: string[] = []
      for (const entry of entries) {
        const fullPath = NodePath.join(skillsDir, entry)
        const stat = await Fs.lstat(fullPath)
        if (stat.isSymbolicLink()) {
          links.push(entry)
        }
      }
      return links
    },
  }).pipe(Effect.orElseSucceed((): string[] => []))
