import { Array, Effect, Predicate } from 'effect'
import { Argument, Command } from 'effect/unstable/cli'

import * as Wt from '#@/lib/worktree.ts'

interface Row {
  readonly name: string
  readonly branch: string
  readonly pr: string
  readonly git: Wt.GitStatus
  readonly path: string
}

const toRow =
  (prMap: ReadonlyMap<string, Wt.PrInfo>, gitMap: ReadonlyMap<string, Wt.GitStatus>) =>
  (entry: Wt.WorktreeEntry & { branch: string }): Row => ({
    branch: entry.branch,
    git: gitMap.get(entry.path) ?? 'committed',
    name: entry.path.split('/').pop() ?? entry.path,
    path: entry.path,
    pr: Wt.formatPr(prMap.get(entry.branch) ?? { number: null, state: 'none' }),
  })

const printRows = (rows: readonly Row[]): Effect.Effect<void> =>
  Effect.sync(() => {
    const nameW = Math.max(4, ...rows.map((r) => r.name.length))
    const branchW = Math.max(6, ...rows.map((r) => r.branch.length))
    const prW = Math.max(2, ...rows.map((r) => r.pr.length))
    const gitW = Math.max(3, ...rows.map((r) => r.git.length))

    console.log(
      `${'NAME'.padEnd(nameW)}  ${'BRANCH'.padEnd(branchW)}  ${'PR'.padEnd(prW)}  ${'GIT'.padEnd(gitW)}  PATH`,
    )
    console.log('-'.repeat(nameW + branchW + prW + gitW + 50))

    // oxlint-disable-next-line rules/no-let
    for (const r of rows) {
      console.log(
        `${r.name.padEnd(nameW)}  ${r.branch.padEnd(branchW)}  ${r.pr.padEnd(prW)}  ${r.git.padEnd(gitW)}  ${r.path}`,
      )
    }
  })

const listWorktrees = (dir: string): Effect.Effect<void> =>
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
    const validRepos = repoResults.filter(Predicate.isNotNull)

    const rowsPerRepo = yield* Effect.forEach(
      validRepos,
      (repo) =>
        Effect.gen(function* () {
          const branches = repo.entries.filter((e): e is Wt.WorktreeEntry & { branch: string } =>
            Predicate.isNotNull(e.branch),
          )
          const [prMap, gitMap] = yield* Effect.all(
            [
              Wt.getPrInfoMap(
                repo.slug,
                branches.map((e) => ({ branch: e.branch, isMain: e.isMain })),
              ),
              Wt.getGitStatusMap(branches.map((e) => e.path)),
            ],
            { concurrency: 'unbounded' },
          )
          return branches.map(toRow(prMap, gitMap))
        }),
      { concurrency: 'unbounded' },
    )

    yield* printRows(rowsPerRepo.flat())
  })

export const lsCommand = Command.make(
  'ls',
  {
    dir: Argument.string('dir').pipe(Argument.withDefault('.')),
  },
  ({ dir }) => listWorktrees(dir),
).pipe(Command.withDescription('List git worktrees with PR status'))
