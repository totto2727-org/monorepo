import { execFile as execFileCb } from 'node:child_process'
import { promisify } from 'node:util'

import { Data, Effect } from 'effect'

const execFile = promisify(execFileCb)

export class GitError extends Data.TaggedError('GitError')<{
  readonly command: string
  readonly message: string
}> {}

const run = (args: readonly string[], cwd?: string): Effect.Effect<string, GitError> =>
  Effect.tryPromise({
    catch: (error) =>
      new GitError({
        command: `git ${args.join(' ')}`,
        message: error instanceof Error ? error.message : String(error),
      }),
    try: async () => {
      const { stdout } = await execFile('git', [...args], { cwd })
      return stdout.trim()
    },
  })

export const checkInstalled: Effect.Effect<void, GitError> = run(['--version']).pipe(Effect.asVoid)

export const clone = (url: string, dest: string): Effect.Effect<void, GitError> =>
  run(['clone', '--depth', '1', url, dest]).pipe(Effect.asVoid)

export const pull = (cwd: string): Effect.Effect<void, GitError> => run(['pull'], cwd).pipe(Effect.asVoid)

export const revParseHead = (cwd: string): Effect.Effect<string, GitError> => run(['rev-parse', 'HEAD'], cwd)

export const checkout = (cwd: string, commitHash: string): Effect.Effect<void, GitError> =>
  run(['fetch', 'origin'], cwd).pipe(
    Effect.flatMap(() => run(['checkout', commitHash], cwd)),
    Effect.asVoid,
  )
