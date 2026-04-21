import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { Effect } from 'effect'

import { getLockFilePath } from '#@/lib/paths.ts'

const SKIP_DIRS = new Set(['.agents', '.git', 'node_modules'])

const collectFrom = async (dir: string, results: string[]): Promise<void> => {
  const agentsDir = NodePath.join(dir, '.agents')
  try {
    await Fs.access(getLockFilePath(agentsDir))
    results.push(agentsDir)
  } catch {
    // no lock file here
  }

  const entries = await Fs.readdir(dir, { withFileTypes: true }).catch(() => [])
  for (const entry of entries) {
    if (entry.isDirectory() && !SKIP_DIRS.has(entry.name)) {
      await collectFrom(NodePath.join(dir, entry.name), results)
    }
  }
}

export const collectAgentsDirs = (startDir: string): Effect.Effect<string[]> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: async () => {
      const results: string[] = []
      await collectFrom(startDir, results)
      return results
    },
  }).pipe(Effect.orElseSucceed((): string[] => []))
