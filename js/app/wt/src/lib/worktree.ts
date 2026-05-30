import { execFile } from 'node:child_process'
import { promisify } from 'node:util'

import { NodeServices } from '@effect/platform-node'
import { Effect, FileSystem, Path, Predicate, Schema, String } from 'effect'

// oxlint-disable-next-line typescript/strict-void-return -- node's promisify(execFile) overloads trigger a false positive
const execFileAsync = promisify(execFile)

const execAsync = async (cmd: string, args: string[]): Promise<string> => {
  const { stdout } = await execFileAsync(cmd, args, { encoding: 'utf-8' })
  return stdout.trim()
}

const execOptional = async (cmd: string, args: string[]): Promise<string> => {
  try {
    return await execAsync(cmd, args)
  } catch {
    return ''
  }
}

// --- JSON parsing ---

const parseJson = (text: string): unknown => JSON.parse(text)

interface RawPr {
  readonly number: number
  readonly state: string
}

const RawPrArray = Schema.Array(Schema.Struct({ number: Schema.Number, state: Schema.String }))
const matchesRawPrArray = Schema.is(RawPrArray)

const parsePrs = (json: string): readonly RawPr[] => {
  if (String.isEmpty(json)) {
    return []
  }
  try {
    const parsed = parseJson(json)
    return matchesRawPrArray(parsed) ? parsed : []
  } catch {
    return []
  }
}

// --- Types ---

export interface WorktreeEntry {
  readonly path: string
  readonly branch: string | null
  readonly isMain: boolean
}

export const BranchedWorktreeEntry = Schema.Struct({
  branch: Schema.String,
  isMain: Schema.Boolean,
  path: Schema.String,
})
export type BranchedWorktreeEntry = Schema.Schema.Type<typeof BranchedWorktreeEntry>
export const matchesBranchedWorktreeEntry = Schema.is(BranchedWorktreeEntry)

export const NonMainWorktreeEntry = Schema.Struct({
  branch: Schema.String,
  isMain: Schema.Literal(false),
  path: Schema.String,
})
export type NonMainWorktreeEntry = Schema.Schema.Type<typeof NonMainWorktreeEntry>
export const matchesNonMainWorktreeEntry = Schema.is(NonMainWorktreeEntry)

export interface RepoWorktrees {
  readonly repoPath: string
  readonly slug: string
  readonly entries: readonly WorktreeEntry[]
}

export type GitStatus = 'pushed' | 'committed' | 'dirty'

export interface PrInfo {
  readonly state: 'main' | 'merged' | 'open' | 'closed' | 'none'
  readonly number: number | null
}

// --- FS discovery ---

export const discoverRepos = (baseDir: string): Effect.Effect<readonly string[]> =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem
    const path = yield* Path.Path
    const isSelfRepo = yield* fs.stat(path.join(baseDir, '.git')).pipe(
      Effect.map((s) => (s.type === 'Directory' ? baseDir : null)),
      Effect.orElseSucceed(() => null),
    )

    const entries = yield* fs.readDirectory(baseDir).pipe(Effect.orElseSucceed(() => [] as readonly string[]))
    // oxlint-disable-next-line unicorn/no-array-method-this-argument -- Effect.forEach, not Array.forEach
    const childRepos = yield* Effect.forEach(entries, (entry) =>
      Effect.gen(function* () {
        const full = path.join(baseDir, entry)
        const stat = yield* fs.stat(full).pipe(Effect.orElseSucceed(() => null))
        if (Predicate.isNullish(stat) || stat.type !== 'Directory' || full === isSelfRepo) {
          return null
        }
        const gitStat = yield* fs.stat(path.join(full, '.git')).pipe(Effect.orElseSucceed(() => null))
        return !Predicate.isNullish(gitStat) && gitStat.type === 'Directory' ? full : null
      }),
    )

    return [isSelfRepo, ...childRepos].filter(Predicate.isNotNullish).toSorted()
  }).pipe(Effect.provide(NodeServices.layer))

// --- Remote parsing ---

const parseOwnerRepo = (path: string): { owner: string; repo: string } | null => {
  const [owner, repo] = path.split('/')
  if (Predicate.isNullish(owner) || String.isEmpty(owner) || Predicate.isNullish(repo) || String.isEmpty(repo)) {
    return null
  }
  return { owner, repo }
}

export const parseGithubRemote = (url: string): { owner: string; repo: string } | null => {
  if (url.startsWith('https://github.com/')) {
    return parseOwnerRepo(url.slice('https://github.com/'.length).replace(/\.git$/u, ''))
  }
  if (url.startsWith('git@github.com:')) {
    return parseOwnerRepo(url.slice('git@github.com:'.length).replace(/\.git$/u, ''))
  }
  return null
}

// --- Worktree parsing ---

export const parseWorktreeList = (output: string, repoPath: string): readonly WorktreeEntry[] =>
  output
    .split('\n\n')
    .map((block) => {
      const lines = block.split('\n')
      const wtPath = lines.find((l) => l.startsWith('worktree '))
      const branchLine = lines.find((l) => l.startsWith('branch refs/heads/'))
      if (Predicate.isNullish(wtPath)) {
        return null
      }
      const path = wtPath.slice('worktree '.length)
      const branch = Predicate.isNullish(branchLine) ? null : branchLine.slice('branch refs/heads/'.length)
      return { branch, isMain: path === repoPath, path } as WorktreeEntry
    })
    .filter(Predicate.isNotNullish)

// --- Async git/gh commands ---

export const fetchRepoWorktrees = (repoPath: string): Effect.Effect<RepoWorktrees | null> =>
  Effect.promise(async () => {
    const results = await Promise.allSettled([
      execAsync('git', ['-C', repoPath, 'remote', 'get-url', 'origin']),
      execAsync('git', ['-C', repoPath, 'worktree', 'list', '--porcelain']),
    ])

    const remoteUrl = results[0].status === 'fulfilled' ? results[0].value : null
    const wtOutput = results[1].status === 'fulfilled' ? results[1].value : null

    if (Predicate.isNullish(remoteUrl) || Predicate.isNullish(wtOutput)) {
      return null
    }

    const slug = parseGithubRemote(remoteUrl.trim())
    if (Predicate.isNullish(slug)) {
      return null
    }

    return {
      entries: parseWorktreeList(wtOutput, repoPath),
      repoPath,
      slug: `${slug.owner}/${slug.repo}`,
    }
  })

// --- PR status (parallel open + closed per branch) ---

const fetchPrInfo = (slug: string, branch: string): Effect.Effect<PrInfo> =>
  Effect.promise(async () => {
    const [openJson, closedJson] = await Promise.all([
      execOptional('gh', [
        'pr',
        'list',
        '--repo',
        slug,
        '--head',
        branch,
        '--state',
        'open',
        '--json',
        'number,state',
        '--limit',
        '1',
      ]),
      execOptional('gh', [
        'pr',
        'list',
        '--repo',
        slug,
        '--head',
        branch,
        '--state',
        'closed',
        '--json',
        'number,state',
        '--limit',
        '1',
      ]),
    ])
    const [openPr] = parsePrs(openJson)
    const [closedPr] = parsePrs(closedJson)

    if (!Predicate.isNullish(openPr)) {
      return { number: openPr.number, state: 'open' as const }
    }
    if (!Predicate.isNullish(closedPr)) {
      const state = closedPr.state === 'MERGED' ? ('merged' as const) : ('closed' as const)
      return { number: closedPr.number, state }
    }
    return { number: null, state: 'none' as const }
  })

export const getPrInfo = (slug: string, branch: string, isMain: boolean): Effect.Effect<PrInfo> => {
  if (isMain) {
    return Effect.succeed({ number: null, state: 'main' as const })
  }
  return fetchPrInfo(slug, branch)
}

export const formatPr = (info: PrInfo): string => {
  switch (info.state) {
    case 'main': {
      return 'main'
    }
    case 'none': {
      return 'none'
    }
    case 'merged': {
      return `MERGED(#${info.number ?? '?'})`
    }
    case 'open': {
      return `OPEN(#${info.number ?? '?'})`
    }
    case 'closed': {
      return `CLOSED(#${info.number ?? '?'})`
    }
    default: {
      return info.state satisfies never
    }
  }
}

export const getPrInfoMap = (
  slug: string,
  branches: readonly { readonly branch: string; readonly isMain: boolean }[],
): Effect.Effect<ReadonlyMap<string, PrInfo>> =>
  Effect.gen(function* () {
    const entries = yield* Effect.forEach(
      branches,
      ({ branch, isMain }) =>
        Effect.map(getPrInfo(slug, branch, isMain), (info): readonly [string, PrInfo] => [branch, info]),
      { concurrency: 'unbounded' },
    )
    return new Map(entries)
  })

// --- Git status (dirty / committed / pushed) ---

export const fetchGitStatus = (worktreePath: string): Effect.Effect<GitStatus> =>
  Effect.promise(async () => {
    const porcelain = await execOptional('git', ['-C', worktreePath, 'status', '--porcelain'])
    if (!String.isEmpty(porcelain)) {
      return 'dirty'
    }
    const ahead = await execOptional('git', ['-C', worktreePath, 'rev-list', '@{u}..HEAD', '--count'])
    if (String.isEmpty(ahead)) {
      return 'committed'
    }
    const count = Number(ahead)
    if (Number.isNaN(count) || count > 0) {
      return 'committed'
    }
    return 'pushed'
  })

export const getGitStatusMap = (worktreePaths: readonly string[]): Effect.Effect<ReadonlyMap<string, GitStatus>> =>
  Effect.gen(function* () {
    const entries = yield* Effect.forEach(
      worktreePaths,
      (path) => Effect.map(fetchGitStatus(path), (status): readonly [string, GitStatus] => [path, status]),
      { concurrency: 'unbounded' },
    )
    return new Map(entries)
  })

// --- Cleanup commands ---

export const removeWorktree = (repoPath: string, worktreePath: string): Effect.Effect<void> =>
  Effect.promise(() => execOptional('git', ['-C', repoPath, 'worktree', 'remove', '--force', worktreePath]))

export const deleteBranch = (repoPath: string, branch: string): Effect.Effect<void> =>
  Effect.promise(() => execOptional('git', ['-C', repoPath, 'branch', '-D', branch]))

export const pruneWorktrees = (repoPath: string): Effect.Effect<void> =>
  Effect.promise(() => execAsync('git', ['-C', repoPath, 'worktree', 'prune']))
