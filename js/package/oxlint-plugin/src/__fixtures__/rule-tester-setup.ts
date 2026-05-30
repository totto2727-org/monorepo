import { RuleTester } from 'oxlint/plugins-dev'
import { describe, it } from 'vite-plus/test'

RuleTester.describe = describe as never
RuleTester.it = it as never
