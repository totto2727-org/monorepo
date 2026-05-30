import { Array, Effect, Predicate } from 'effect'
import { Argument, Command, Flag } from 'effect/unstable/cli'

import * as Wt from '#@/lib/worktree.ts'

interface BranchWithStatus {
  readonly entry: Wt.NonMainWorktreeEntry
  readonly pr: Wt.PrInfo
  readonly git: Wt.GitStatus
  readonly reason: string
}

interface RepoCleanup {
  readonly repoPath: string
  readonly removable: readonly BranchWithStatus[]
  readonly skipped: number
}

const classifyForRemoval = (pr: Wt.PrInfo, git: Wt.GitStatus): string | null => {
  if (pr.state === 'merged') {
    return 'merged'
  }
  if (git !== 'pushed') {
    return null
  }
  if (pr.state === 'closed') {
    return 'closed (pushed)'
  }
  if (pr.state === 'none') {
    return 'no PR (pushed)'
  }
  return null
}

const classifyEntry =
  (prMap: ReadonlyMap<string, Wt.PrInfo>, gitMap: ReadonlyMap<string, Wt.GitStatus>) =>
  (entry: Wt.NonMainWorktreeEntry): BranchWithStatus | null => {
    const pr = prMap.get(entry.branch) ?? { number: null, state: 'none' as const }
    const git = gitMap.get(entry.path) ?? 'committed'
    const reason = classifyForRemoval(pr, git)
    if (Predicate.isNullish(reason)) {
      return null
    }
    return { entry, git, pr, reason }
  }

const classifyRepo = (repo: Wt.RepoWorktrees): Effect.Effect<RepoCleanup> =>
  Effect.gen(function* () {
    const nonMain = repo.entries.filter(Wt.matchesNonMainWorktreeEntry)

    if (Array.isReadonlyArrayEmpty(nonMain)) {
      return { removable: [], repoPath: repo.repoPath, skipped: 0 }
    }

    const [prMap, gitMap] = yield* Effect.all(
      [
        Wt.getPrInfoMap(
          repo.slug,
          nonMain.map((entry) => ({ branch: entry.branch, isMain: false })),
        ),
        Wt.getGitStatusMap(nonMain.map((entry) => entry.path)),
      ],
      { concurrency: 'unbounded' },
    )

    const classify = classifyEntry(prMap, gitMap)
    const removable = nonMain.map(classify).filter(Predicate.isNotNullish)
    const skipped = nonMain.length - removable.length

    return { removable, repoPath: repo.repoPath, skipped }
  })

const logRemoval = (item: BranchWithStatus, dryRun: boolean): Effect.Effect<void> =>
  Effect.sync(() => {
    const prefix = dryRun ? '[dry-run] Would remove' : 'Removing'
    console.log(`${prefix}: ${item.entry.path} (${item.entry.branch}, ${item.reason})`)
  })

const executeRepoCleanup = (cleanup: RepoCleanup, dryRun: boolean): Effect.Effect<number> =>
  Effect.gen(function* () {
    if (Array.isReadonlyArrayEmpty(cleanup.removable)) {
      return 0
    }

    if (dryRun) {
      yield* Effect.forEach(cleanup.removable, (item) => logRemoval(item, true), {
        concurrency: 'unbounded',
      })
      return cleanup.removable.length
    }

    yield* Effect.forEach(
      cleanup.removable,
      (item) =>
        Effect.gen(function* () {
          yield* logRemoval(item, false)
          yield* Wt.removeWorktree(cleanup.repoPath, item.entry.path)
          yield* Wt.deleteBranch(cleanup.repoPath, item.entry.branch)
        }),
      { concurrency: 'unbounded' },
    )
    yield* Wt.pruneWorktrees(cleanup.repoPath)

    return cleanup.removable.length
  })

const cleanupWorktrees = (dir: string, dryRun: boolean): Effect.Effect<void> =>
  Effect.gen(function* () {
    const resolvedDir = dir === '.' ? process.cwd() : dir
    const repos = yield* Wt.discoverRepos(resolvedDir)
    if (Array.isReadonlyArrayEmpty(repos)) {
      yield* Effect.sync(() => {
        console.log('No git repositories found.')
      })
      return
    }

    const repoResults = yield* Effect.forEach(repos, Wt.fetchRepoWorktrees, { concurrency: 'unbounded' })
    const validRepos = repoResults.filter(Predicate.isNotNullish)

    const repoCleanups = yield* Effect.forEach(validRepos, classifyRepo, { concurrency: 'unbounded' })

    const removedCounts = yield* Effect.forEach(repoCleanups, (cleanup) => executeRepoCleanup(cleanup, dryRun), {
      concurrency: 1,
    })
    const totalRemoved = Array.reduce(removedCounts, 0, (acc, n) => acc + n)
    const totalSkipped = Array.reduce(repoCleanups, 0, (acc, cleanup) => acc + cleanup.skipped)

    yield* Effect.sync(() => {
      console.log(`Done: ${totalRemoved} removed, ${totalSkipped} skipped${dryRun ? ' (dry-run)' : ''}`)
    })
  })

export const cleanupCommand = Command.make(
  'cleanup',
  {
    dir: Argument.string('dir').pipe(Argument.withDefault('.')),
    dryRun: Flag.boolean('dry-run').pipe(Flag.withAlias('n'), Flag.withDefault(false)),
  },
  ({ dir, dryRun }) => cleanupWorktrees(dir, dryRun),
).pipe(Command.withDescription('Remove worktrees with merged or no PR'))
