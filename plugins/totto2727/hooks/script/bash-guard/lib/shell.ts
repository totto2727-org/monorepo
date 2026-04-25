/**
 * Minimal shell tokenizer.
 *
 * Splits a command string into word tokens and operator tokens, respecting
 * single/double quotes and backslash escapes. Operators are command separators
 * such as `;`, `&&`, `||`, `|`, `&`.
 *
 * This is intentionally NOT a full shell parser — it does not expand variables,
 * resolve subshells, evaluate command substitution, or handle redirections.
 * It is sufficient for inspecting Bash commands at hook time.
 */

export type Token =
  | { readonly type: 'word'; readonly value: string }
  | { readonly type: 'op'; readonly value: ';' | '&&' | '||' | '|' | '&' }

export function tokenize(command: string): Token[] {
  const tokens: Token[] = []
  let current = ''
  let inSingle = false
  let inDouble = false
  let escaped = false
  let i = 0

  const flushWord = () => {
    if (current.length > 0) {
      tokens.push({ type: 'word', value: current })
      current = ''
    }
  }

  while (i < command.length) {
    const ch = command[i]

    if (escaped) {
      current += ch
      escaped = false
      i++
      continue
    }

    if (ch === '\\' && !inSingle) {
      escaped = true
      i++
      continue
    }

    if (ch === "'" && !inDouble) {
      inSingle = !inSingle
      i++
      continue
    }

    if (ch === '"' && !inSingle) {
      inDouble = !inDouble
      i++
      continue
    }

    if (!inSingle && !inDouble) {
      if (ch === '&' && command[i + 1] === '&') {
        flushWord()
        tokens.push({ type: 'op', value: '&&' })
        i += 2
        continue
      }
      if (ch === '|' && command[i + 1] === '|') {
        flushWord()
        tokens.push({ type: 'op', value: '||' })
        i += 2
        continue
      }
      if (ch === ';' || ch === '|' || ch === '&') {
        flushWord()
        tokens.push({ type: 'op', value: ch })
        i++
        continue
      }
      if (/\s/.test(ch)) {
        flushWord()
        i++
        continue
      }
    }

    current += ch
    i++
  }

  flushWord()
  return tokens
}

/**
 * Splits a tokenized command stream into individual command argv arrays at
 * operator boundaries (`;`, `&&`, `||`, `|`, `&`).
 */
export function splitCommands(tokens: readonly Token[]): string[][] {
  const commands: string[][] = []
  let current: string[] = []
  for (const tok of tokens) {
    if (tok.type === 'op') {
      if (current.length > 0) {
        commands.push(current)
        current = []
      }
    } else {
      current.push(tok.value)
    }
  }
  if (current.length > 0) commands.push(current)
  return commands
}

/**
 * Returns true when a token has the shape of a shell environment variable
 * assignment prefix (e.g. `FOO=bar`, `CI=true`).
 */
export function isEnvAssignment(token: string): boolean {
  return /^[A-Za-z_][A-Za-z0-9_]*=/.test(token)
}

/**
 * Returns the index of the first non-prefix token in an argv array,
 * skipping any leading env-assignment tokens and a single optional `export`
 * keyword.
 */
export function skipEnvPrefix(argv: readonly string[]): number {
  let i = 0
  while (i < argv.length) {
    const t = argv[i]
    if (t === 'export') {
      i++
      while (i < argv.length && isEnvAssignment(argv[i])) i++
      return i
    }
    if (isEnvAssignment(t)) {
      i++
      continue
    }
    return i
  }
  return i
}
