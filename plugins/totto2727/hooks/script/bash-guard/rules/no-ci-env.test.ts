import { noCiEnv } from './no-ci-env.ts'

function assert(cond: unknown, msg: string): asserts cond {
  if (!cond) throw new Error(msg)
}

Deno.test('blocks CI=true npm test', () => {
  const r = noCiEnv.check('CI=true npm test')
  assert(r !== null, 'expected violation')
  assert(r.rule === 'no-ci-env', `wrong rule: ${r.rule}`)
})

Deno.test('blocks CI=1 cmd', () => {
  assert(noCiEnv.check('CI=1 echo hi') !== null, 'expected violation')
})

Deno.test('blocks CI=yes cmd', () => {
  assert(noCiEnv.check('CI=yes pnpm test') !== null, 'expected violation')
})

Deno.test('blocks export CI=true', () => {
  assert(noCiEnv.check('export CI=true') !== null, 'expected violation')
})

Deno.test('blocks CI=true between other env prefixes', () => {
  assert(noCiEnv.check('FOO=1 CI=true BAR=2 cmd') !== null, 'expected violation')
})

Deno.test('blocks CI=true in second segment of compound command', () => {
  assert(noCiEnv.check('echo a && CI=true cmd') !== null, 'expected violation')
})

Deno.test('allows CI=false cmd', () => {
  assert(noCiEnv.check('CI=false npm test') === null, 'unexpected violation')
})

Deno.test('allows plain npm test', () => {
  assert(noCiEnv.check('npm test') === null, 'unexpected violation')
})

Deno.test('allows CI=true literal inside double quotes (echo)', () => {
  assert(noCiEnv.check('echo "CI=true"') === null, 'unexpected violation')
})

Deno.test('allows CI=true literal inside single quotes', () => {
  assert(noCiEnv.check(`echo 'CI=true'`) === null, 'unexpected violation')
})

Deno.test('allows CI_OTHER=true (different var name)', () => {
  assert(noCiEnv.check('CI_OTHER=true cmd') === null, 'unexpected violation')
})

Deno.test('allows RECIPI=true (does not match CI=)', () => {
  assert(noCiEnv.check('RECIPI=true cmd') === null, 'unexpected violation')
})

Deno.test('violation includes resolution', () => {
  const r = noCiEnv.check('CI=true cmd')
  assert(r !== null, 'expected violation')
  assert(r.resolution.length > 0, 'resolution should be set')
})
