import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { isReportable } from '../helpers.ts'

export const hasStringStyleValue = (node: unknown): boolean =>
  Predicate.isObject(node) &&
  node.type === 'JSXAttribute' &&
  Predicate.isObject(node.name) &&
  (node.name as { name?: string }).name === 'style' &&
  Predicate.isObject(node.value) &&
  (node.value as { type?: string }).type === 'Literal' &&
  Predicate.isString((node.value as { value?: unknown }).value)

const rule: Rule = {
  create(context: Context) {
    return {
      JSXAttribute(node: unknown) {
        if (!isReportable(node)) {
          return
        }
        if (hasStringStyleValue(node)) {
          context.report({
            message: 'Use object-style `style={{ ... }}` instead of string `style="..."`.',
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
