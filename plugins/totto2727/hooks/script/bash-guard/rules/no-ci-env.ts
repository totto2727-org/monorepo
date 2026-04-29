import { isEnvAssignment, splitCommands, tokenize } from '../lib/shell.ts'
import type { Rule, RuleViolation } from './types.ts'

const TRUTHY = new Set(['true', '1', 'yes', 'on', 'TRUE', 'YES', 'ON', 'True', 'Yes', 'On'])

const CI_ASSIGNMENT = /^CI=(.+)$/

/**
 * Looks for `CI=<truthy>` assignment tokens that would actually be applied
 * to a command — i.e. either a leading env-var prefix (`CI=true cmd ...`),
 * or following the `export` keyword.
 *
 * Tokens inside quoted strings (e.g. `echo "CI=true"`) are not detected
 * because they are not assignments.
 */
function scanCmd(argv: readonly string[]): RuleViolation | null {
  let i = 0
  while (i < argv.length) {
    const t = argv[i]
    if (t === 'export') {
      i++
      while (i < argv.length && isEnvAssignment(argv[i])) {
        const v = checkToken(argv[i])
        if (v) return v
        i++
      }
      return null
    }
    if (isEnvAssignment(t)) {
      const v = checkToken(t)
      if (v) return v
      i++
      continue
    }
    return null
  }
  return null
}

function checkToken(token: string): RuleViolation | null {
  const m = CI_ASSIGNMENT.exec(token)
  if (!m) return null
  if (!TRUTHY.has(m[1])) return null
  return {
    rule: 'no-ci-env',
    message: `Setting \`${token}\` is forbidden in this repository.`,
    resolution:
      'Run the command without the CI environment variable. CI behavior should not be triggered locally — see MEMORY (feedback_no_ci_env).',
  }
}

export const noCiEnv: Rule = {
  name: 'no-ci-env',
  check(command) {
    for (const cmd of splitCommands(tokenize(command))) {
      const v = scanCmd(cmd)
      if (v) return v
    }
    return null
  },
}
