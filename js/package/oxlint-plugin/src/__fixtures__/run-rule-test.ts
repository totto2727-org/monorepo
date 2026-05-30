import type { Rule } from '@oxlint/plugins'
import { RuleTester } from 'oxlint/plugins-dev'

type RunArgs = Parameters<InstanceType<typeof RuleTester>['run']>
type TesterRule = RunArgs[1]
type TesterTests = RunArgs[2]

export const runRuleTest = (ruleName: string, rule: Rule, tests: TesterTests): void => {
  const tester = new RuleTester()
  tester.run(ruleName, rule as TesterRule, tests)
}
