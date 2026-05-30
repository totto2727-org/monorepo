import * as Fs from 'node:fs/promises'
import * as NodePath from 'node:path'

import { Effect } from 'effect'
import { Command } from 'effect/unstable/cli'

import { getLockFilePath } from '#@/lib/paths.ts'
import { emptyLockFile } from '#@/schema/lock-file.ts'

export const initLockFile = (projectRoot: string): Effect.Effect<void, unknown> =>
  Effect.tryPromise({
    catch: (e: unknown) => e,
    try: async () => {
      const agentsDir = NodePath.join(projectRoot, '.agents')
      const lockPath = getLockFilePath(agentsDir)

      await Fs.mkdir(agentsDir, { recursive: true })
      await Fs.writeFile(lockPath, `${JSON.stringify(emptyLockFile, null, '\t')}\n`, { encoding: 'utf-8', flag: 'wx' })
    },
  })

export const initCommand = Command.make('init', {}, () => initLockFile(process.cwd())).pipe(
  Command.withDescription('Create an empty lock file in the current directory'),
)
