import type { Context, Rule } from '@oxlint/plugins'
import { Predicate, String } from 'effect'

import { isEqualityOperator, isReportable } from '../helpers.ts'

export const isEmptyStringLiteral = (node: unknown): boolean =>
  Predicate.isObject(node) && node.type === 'Literal' && Predicate.isString(node.value) && String.isEmpty(node.value)

const rule: Rule = {
  create(context: Context) {
    return {
      BinaryExpression(node: unknown) {
        if (!isReportable(node)) {
          return
        }
        if (Predicate.isObject(node) && isEqualityOperator(node.operator)) {
          const leftEmpty = isEmptyStringLiteral(node.left)
          const rightEmpty = isEmptyStringLiteral(node.right)
          if (!leftEmpty && !rightEmpty) {
            return
          }
          const isEquality = node.operator === '==' || node.operator === '==='
          const predicateFn = isEquality ? 'String.isEmpty' : 'String.isNonEmpty'
          context.report({
            message: `Use ${predicateFn}() instead of direct empty string comparison`,
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
