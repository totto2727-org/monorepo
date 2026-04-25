import { noCiEnv } from './no-ci-env.ts'
import { noGitC } from './no-git-c.ts'
import { noPackageManagerCi } from './no-package-manager-ci.ts'
import type { Rule } from './types.ts'

export const rules: readonly Rule[] = [noCiEnv, noPackageManagerCi, noGitC]
