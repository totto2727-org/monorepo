// oxlint-disable max-classes-per-file -- TaggedError subclasses are grouped by domain
import { execFile as execFileCb } from 'node:child_process'
import { dirname, isAbsolute, join, resolve } from 'node:path'
import { promisify } from 'node:util'

import { Data, Effect, FileSystem, Predicate, String } from 'effect'

// oxlint-disable-next-line typescript-eslint/strict-void-return -- node child_process callbacks return a ChildProcess, not void
const execFile = promisify(execFileCb)

export class RepoRootNotFoundError extends Data.TaggedError('RepoRootNotFoundError')<{
  readonly startedFrom: string
}> {}

export class GitCommandError extends Data.TaggedError('GitCommandError')<{
  readonly command: string
  readonly message: string
}> {}

export interface Worktree {
  readonly id: string
  readonly path: string
  readonly branch: string | null
  readonly head: string
  readonly isMain: boolean
}

export const findRepoRoot = (start: string): Effect.Effect<string, RepoRootNotFoundError, FileSystem.FileSystem> => {
  const recurse = (current: string): Effect.Effect<string, RepoRootNotFoundError, FileSystem.FileSystem> =>
    Effect.gen(function* () {
      const fs = yield* FileSystem.FileSystem
      const gitPath = join(current, '.git')
      const exists = yield* fs.exists(gitPath).pipe(Effect.orElseSucceed(() => false))
      if (exists) {
        return current
      }
      const parent = dirname(current)
      if (parent === current) {
        return yield* new RepoRootNotFoundError({ startedFrom: start })
      }
      return yield* recurse(parent)
    })
  return recurse(resolve(start))
}

const parseBlock = (block: string, isMain: boolean): Worktree | null => {
  const lines = block.split('\n')
  const pathLine = lines.find((l) => l.startsWith('worktree '))
  if (Predicate.isNullish(pathLine)) {
    return null
  }
  const prunable = lines.some((l) => l === 'prunable' || l.startsWith('prunable '))
  if (prunable) {
    return null
  }
  const headLine = lines.find((l) => l.startsWith('HEAD '))
  const branchLine = lines.find((l) => l.startsWith('branch refs/heads/'))
  const detached = lines.some((l) => l === 'detached')
  const path = pathLine.slice('worktree '.length).trim()
  const head = Predicate.isNullish(headLine) ? '' : headLine.slice('HEAD '.length).trim()
  const branch =
    Predicate.isNullish(branchLine) || detached ? null : branchLine.slice('branch refs/heads/'.length).trim()
  const id = branch ?? `head-${head.slice(0, 8)}`
  return { branch, head, id, isMain, path }
}

const parsePorcelain = (output: string): readonly Worktree[] =>
  output
    .split(/\n\n+/)
    .map((b) => b.trim())
    .filter((b) => String.isNonEmpty(b))
    .map((block, i) => parseBlock(block, i === 0))
    .filter((w) => Predicate.isNotNullish(w))

const runGit = (cmd: string, args: readonly string[], cwd: string): Effect.Effect<string, GitCommandError> =>
  Effect.tryPromise({
    catch: (error): GitCommandError =>
      new GitCommandError({
        command: `${cmd} ${args.join(' ')}`,
        message: error instanceof Error ? error.message : globalThis.String(error),
      }),
    try: async () => {
      const result = await execFile(cmd, [...args], { cwd })
      return result.stdout
    },
  })

export const listWorktrees = (repoRoot: string): Effect.Effect<readonly Worktree[], GitCommandError> =>
  runGit('git', ['worktree', 'list', '--porcelain'], repoRoot).pipe(Effect.map(parsePorcelain))

export interface ResolvedDir {
  readonly repoRoot: string
  readonly dir: string
}

export const resolveDirAgainstRepoRoot = (
  relativeDir: string,
): Effect.Effect<ResolvedDir, RepoRootNotFoundError, FileSystem.FileSystem> =>
  Effect.gen(function* () {
    const repoRoot = yield* findRepoRoot(process.cwd())
    const dir = isAbsolute(relativeDir) ? relativeDir : join(repoRoot, relativeDir)
    return { dir, repoRoot }
  })
