import { noGitC } from './no-git-c.ts'

function assert(cond: unknown, msg: string): asserts cond {
  if (!cond) throw new Error(msg)
}

Deno.test('blocks git -C /path status', () => {
  const r = noGitC.check('git -C /path status')
  assert(r !== null, 'expected violation')
  assert(r.rule === 'no-git-c', `wrong rule: ${r.rule}`)
})

Deno.test('blocks git -C with relative path', () => {
  assert(noGitC.check('git -C ./sub status') !== null, 'expected violation')
})

Deno.test('blocks git --no-pager -C /path status (option order swapped)', () => {
  assert(noGitC.check('git --no-pager -C /path status') !== null, 'expected violation')
})

Deno.test('blocks git -c user.name=foo -C /path status (after value-taking option)', () => {
  assert(noGitC.check('git -c user.name=foo -C /path status') !== null, 'expected violation')
})

Deno.test('blocks git --git-dir /path/.git -C /work status', () => {
  assert(noGitC.check('git --git-dir /path/.git -C /work status') !== null, 'expected violation')
})

Deno.test('blocks git -C inside compound command', () => {
  assert(noGitC.check('echo a && git -C foo status') !== null, 'expected violation')
})

Deno.test('blocks git -C piped', () => {
  assert(noGitC.check('git -C foo log | cat') !== null, 'expected violation')
})

Deno.test('blocks git -C with env prefix', () => {
  assert(noGitC.check('GIT_PAGER=cat git -C foo status') !== null, 'expected violation')
})

Deno.test('allows plain git status', () => {
  assert(noGitC.check('git status') === null, 'unexpected violation')
})

Deno.test('allows git diff -C (subcommand flag, not global)', () => {
  assert(noGitC.check('git diff -C HEAD~1') === null, 'unexpected violation')
})

Deno.test('allows git log --grep -C (subcommand flag)', () => {
  assert(noGitC.check('git log -C') === null, 'unexpected violation')
})

Deno.test('allows non-git command containing -C', () => {
  assert(noGitC.check('grep -C 3 pattern file') === null, 'unexpected violation')
})

Deno.test('allows git with --no-pager only', () => {
  assert(noGitC.check('git --no-pager log') === null, 'unexpected violation')
})

Deno.test('allows cd then git status (cd handled separately)', () => {
  assert(noGitC.check('cd foo && git status') === null, 'unexpected violation')
})

Deno.test('resolution mentions cd alternative', () => {
  const r = noGitC.check('git -C foo status')
  assert(r !== null, 'expected violation')
  assert(/cd/.test(r.resolution), 'resolution should mention cd alternative')
})
