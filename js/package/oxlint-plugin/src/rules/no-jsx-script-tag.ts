import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { isReportable } from '../helpers.ts'

export const isScriptJsxElement = (node: unknown): boolean =>
  Predicate.isObject(node) &&
  node.type === 'JSXOpeningElement' &&
  Predicate.isObject(node.name) &&
  (node.name as { type?: string }).type === 'JSXIdentifier' &&
  (node.name as { name?: string }).name === 'script'

const rule: Rule = {
  create(context: Context) {
    return {
      JSXOpeningElement(node: unknown) {
        if (!isReportable(node)) {
          return
        }
        if (isScriptJsxElement(node)) {
          context.report({
            message:
              'Do not use <script> tags in JSX. Write client-side logic in React or Remix v3 components instead. If unavoidable (e.g. a third-party inline script), disable this rule with an oxlint-disable comment that includes the reason.',
            node,
          })
        }
      },
    }
  },
  meta: {
    type: 'problem',
  },
}

export default rule
