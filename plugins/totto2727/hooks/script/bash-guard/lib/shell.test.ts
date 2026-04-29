import { isEnvAssignment, skipEnvPrefix, splitCommands, tokenize } from './shell.ts'

function assertEquals<T>(actual: T, expected: T, msg?: string): void {
  const a = JSON.stringify(actual)
  const e = JSON.stringify(expected)
  if (a !== e) {
    throw new Error(`${msg ?? 'assertEquals failed'}\n  expected: ${e}\n  actual:   ${a}`)
  }
}

Deno.test('tokenize: simple words', () => {
  assertEquals(
    tokenize('npm test'),
    [
      { type: 'word', value: 'npm' },
      { type: 'word', value: 'test' },
    ],
  )
})

Deno.test('tokenize: double-quoted string keeps spaces', () => {
  assertEquals(
    tokenize('echo "hello world"'),
    [
      { type: 'word', value: 'echo' },
      { type: 'word', value: 'hello world' },
    ],
  )
})

Deno.test('tokenize: single quotes preserve content literally', () => {
  assertEquals(
    tokenize(`echo 'a b'`),
    [
      { type: 'word', value: 'echo' },
      { type: 'word', value: 'a b' },
    ],
  )
})

Deno.test('tokenize: escape with backslash', () => {
  assertEquals(
    tokenize('echo a\\ b'),
    [
      { type: 'word', value: 'echo' },
      { type: 'word', value: 'a b' },
    ],
  )
})

Deno.test('tokenize: && and || and ; operators', () => {
  assertEquals(
    tokenize('a && b || c ; d'),
    [
      { type: 'word', value: 'a' },
      { type: 'op', value: '&&' },
      { type: 'word', value: 'b' },
      { type: 'op', value: '||' },
      { type: 'word', value: 'c' },
      { type: 'op', value: ';' },
      { type: 'word', value: 'd' },
    ],
  )
})

Deno.test('tokenize: pipe', () => {
  assertEquals(
    tokenize('a | b'),
    [
      { type: 'word', value: 'a' },
      { type: 'op', value: '|' },
      { type: 'word', value: 'b' },
    ],
  )
})

Deno.test('tokenize: env var assignment kept as one token', () => {
  assertEquals(
    tokenize('CI=true npm test'),
    [
      { type: 'word', value: 'CI=true' },
      { type: 'word', value: 'npm' },
      { type: 'word', value: 'test' },
    ],
  )
})

Deno.test('splitCommands: splits at operators', () => {
  const tokens = tokenize('a b && c d ; e')
  assertEquals(splitCommands(tokens), [['a', 'b'], ['c', 'd'], ['e']])
})

Deno.test('splitCommands: empty input', () => {
  assertEquals(splitCommands([]), [])
})

Deno.test('isEnvAssignment: matches FOO=bar', () => {
  assertEquals(isEnvAssignment('FOO=bar'), true)
  assertEquals(isEnvAssignment('CI=true'), true)
  assertEquals(isEnvAssignment('_X=1'), true)
  assertEquals(isEnvAssignment('foo=bar'), true)
})

Deno.test('isEnvAssignment: rejects non-assignment', () => {
  assertEquals(isEnvAssignment('--foo=bar'), false)
  assertEquals(isEnvAssignment('1FOO=bar'), false)
  assertEquals(isEnvAssignment('FOO'), false)
})

Deno.test('skipEnvPrefix: skips leading assignments', () => {
  assertEquals(skipEnvPrefix(['FOO=1', 'BAR=2', 'cmd', 'arg']), 2)
})

Deno.test('skipEnvPrefix: skips export form', () => {
  assertEquals(skipEnvPrefix(['export', 'FOO=1', 'BAR=2']), 3)
})

Deno.test('skipEnvPrefix: no prefix returns 0', () => {
  assertEquals(skipEnvPrefix(['cmd', 'arg']), 0)
})

Deno.test('skipEnvPrefix: empty', () => {
  assertEquals(skipEnvPrefix([]), 0)
})
