import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { isReportable } from '../helpers.ts'

const FORBIDDEN_DATE_STATIC_METHODS: ReadonlySet<string> = new Set(['now', 'parse', 'UTC'])

export const isDateIdentifier = (node: unknown): boolean =>
  Predicate.isObject(node) && node.type === 'Identifier' && node.name === 'Date'

export const getForbiddenDateStaticMethod = (node: unknown): string | null => {
  if (
    Predicate.isObject(node) &&
    node.type === 'MemberExpression' &&
    node.computed !== true &&
    isDateIdentifier(node.object) &&
    Predicate.isObject(node.property) &&
    node.property.type === 'Identifier' &&
    Predicate.isString(node.property.name) &&
    FORBIDDEN_DATE_STATIC_METHODS.has(node.property.name)
  ) {
    return node.property.name
  }
  return null
}

const rule: Rule = {
  create(context: Context) {
    return {
      MemberExpression(node: unknown) {
        if (!isReportable(node)) {
          return
        }
        const method = getForbiddenDateStaticMethod(node)
        if (Predicate.isNotNullish(method)) {
          context.report({
            message: `Use Effect \`DateTime\` / \`Duration\` instead of \`Date.${method}()\`. Native \`Date\` is allowed only at external-API boundaries.`,
            node,
          })
        }
      },
      NewExpression(node: unknown) {
        if (!isReportable(node)) {
          return
        }
        if (Predicate.isObject(node) && isDateIdentifier(node.callee)) {
          context.report({
            message:
              'Use Effect `DateTime` / `Duration` instead of `new Date()`. Native `Date` is allowed only at external-API boundaries.',
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
