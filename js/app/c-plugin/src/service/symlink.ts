import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { Effect } from 'effect'

import { getSkillsDir } from '#@/lib/paths.ts'

export const createSkillLink = (agentsDir: string, skillName: string, targetPath: string): Effect.Effect<void> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: async () => {
      const skillsDir = getSkillsDir(agentsDir)
      const linkPath = NodePath.join(skillsDir, skillName)
      const relativePath = NodePath.relative(skillsDir, targetPath)
      try {
        await Fs.unlink(linkPath)
      } catch {
        // ignore if not exists
      }
      await Fs.symlink(relativePath, linkPath)
    },
  }).pipe(Effect.ignore)

export const removeSkillLink = (agentsDir: string, skillName: string): Effect.Effect<void> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: async () => {
      const linkPath = NodePath.join(getSkillsDir(agentsDir), skillName)
      await Fs.unlink(linkPath)
    },
  }).pipe(Effect.ignore)

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
