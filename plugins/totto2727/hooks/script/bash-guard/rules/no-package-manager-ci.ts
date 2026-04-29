import { skipEnvPrefix, splitCommands, tokenize } from '../lib/shell.ts'
import type { Rule, RuleViolation } from './types.ts'

const PACKAGE_MANAGERS = new Set(['npm', 'pnpm', 'yarn', 'bun', 'vp'])

const RESOLUTION: Record<string, string> = {
  npm: 'Use `npm install` instead. `npm ci` removes node_modules and reinstalls from the lockfile — appropriate only for CI runners.',
  pnpm:
    'Use `pnpm install` (or `pnpm install --frozen-lockfile` if you need a CI-style lockfile check) instead.',
  yarn: 'Use `yarn install` (Yarn does not have a `ci` subcommand).',
  bun: 'Use `bun install --frozen-lockfile` if you need a lockfile-strict install (Bun does not have a `ci` subcommand).',
  vp: 'Use `vp install` (or whichever non-`ci` workflow your task needs). `vp ci` is reserved for CI environments.',
}

export const noPackageManagerCi: Rule = {
  name: 'no-package-manager-ci',
  check(command) {
    for (const cmd of splitCommands(tokenize(command))) {
      const start = skipEnvPrefix(cmd)
      const exec = cmd[start]
      const sub = cmd[start + 1]
      if (exec === undefined || sub !== 'ci') continue
      if (!PACKAGE_MANAGERS.has(exec)) continue
      const violation: RuleViolation = {
        rule: 'no-package-manager-ci',
        message: `\`${exec} ci\` is forbidden. CI-style installs should only run inside the CI pipeline.`,
        resolution: RESOLUTION[exec] ?? 'Use the package manager\'s regular install command.',
      }
      return violation
    }
    return null
  },
}
