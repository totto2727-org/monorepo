import { noPackageManagerCi } from './no-package-manager-ci.ts'

function assert(cond: unknown, msg: string): asserts cond {
  if (!cond) throw new Error(msg)
}

Deno.test('blocks npm ci', () => {
  const r = noPackageManagerCi.check('npm ci')
  assert(r !== null, 'expected violation')
  assert(r.rule === 'no-package-manager-ci', `wrong rule: ${r.rule}`)
})

Deno.test('blocks pnpm ci', () => {
  assert(noPackageManagerCi.check('pnpm ci') !== null, 'expected violation')
})

Deno.test('blocks yarn ci', () => {
  assert(noPackageManagerCi.check('yarn ci') !== null, 'expected violation')
})

Deno.test('blocks bun ci', () => {
  assert(noPackageManagerCi.check('bun ci') !== null, 'expected violation')
})

Deno.test('blocks vp ci', () => {
  assert(noPackageManagerCi.check('vp ci') !== null, 'expected violation')
})

Deno.test('blocks npm ci with extra args', () => {
  assert(noPackageManagerCi.check('npm ci --legacy-peer-deps') !== null, 'expected violation')
})

Deno.test('blocks npm ci behind env prefix', () => {
  assert(noPackageManagerCi.check('FOO=bar npm ci') !== null, 'expected violation')
})

Deno.test('blocks npm ci behind export prefix', () => {
  assert(noPackageManagerCi.check('export FOO=1 && npm ci') !== null, 'expected violation')
})

Deno.test('blocks npm ci in second segment', () => {
  assert(noPackageManagerCi.check('cd foo && npm ci') !== null, 'expected violation')
})

Deno.test('blocks npm ci piped', () => {
  assert(noPackageManagerCi.check('echo a | npm ci') !== null, 'expected violation')
})

Deno.test('allows npm install', () => {
  assert(noPackageManagerCi.check('npm install') === null, 'unexpected violation')
})

Deno.test('allows pnpm install --frozen-lockfile', () => {
  assert(noPackageManagerCi.check('pnpm install --frozen-lockfile') === null, 'unexpected violation')
})

Deno.test('allows npm citgen (different word, would not tokenize as ci)', () => {
  assert(noPackageManagerCi.check('npm citgen') === null, 'unexpected violation')
})

Deno.test('allows non-package-manager ci command', () => {
  assert(noPackageManagerCi.check('mycli ci') === null, 'unexpected violation')
})

Deno.test('resolution mentions install', () => {
  const r = noPackageManagerCi.check('npm ci')
  assert(r !== null, 'expected violation')
  assert(/install/i.test(r.resolution), 'resolution should suggest install')
})
