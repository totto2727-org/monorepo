import { skipEnvPrefix, splitCommands, tokenize } from '../lib/shell.ts'
import type { Rule, RuleViolation } from './types.ts'

const VALUE_TAKING_SHORT = new Set(['-c'])
const VALUE_TAKING_LONG = new Set([
  '--git-dir',
  '--work-tree',
  '--exec-path',
  '--namespace',
  '--super-prefix',
  '--config-env',
  '--list-cmds',
])

/**
 * Returns true if `arg` is a git global option that takes a value as the
 * NEXT token (not via `--key=value` form).
 */
function consumesNextValue(arg: string): boolean {
  if (VALUE_TAKING_SHORT.has(arg)) return true
  return VALUE_TAKING_LONG.has(arg)
}

/**
 * Walks the global-option region of a `git ...` argv (i.e. the tokens between
 * `git` and the subcommand), returning a violation if `-C` is found.
 *
 * Stops at the first non-flag token, which is treated as the subcommand.
 * `-C <path>` after the subcommand belongs to that subcommand (e.g. `git diff
 * -C` is a copy-detection flag) and is intentionally not flagged.
 */
function scanGitArgv(argv: readonly string[], gitIndex: number): RuleViolation | null {
  let j = gitIndex + 1
  while (j < argv.length) {
    const t = argv[j]
    if (t === '-C') {
      return {
        rule: 'no-git-c',
        message: '`git -C <dir>` is forbidden in this repository.',
        resolution:
          'Run git from the directory it should operate on, or `cd` there first as a separate step. Avoid `-C` so the working tree of the command is unambiguous.',
      }
    }
    if (!t.startsWith('-')) return null
    if (consumesNextValue(t)) {
      j += 2
      continue
    }
    j++
  }
  return null
}

export const noGitC: Rule = {
  name: 'no-git-c',
  check(command) {
    for (const cmd of splitCommands(tokenize(command))) {
      const start = skipEnvPrefix(cmd)
      if (cmd[start] !== 'git') continue
      const v = scanGitArgv(cmd, start)
      if (v) return v
    }
    return null
  },
}
