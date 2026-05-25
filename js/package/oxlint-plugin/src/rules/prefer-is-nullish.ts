import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { isReportable } from '../helpers.ts'

const NULLISH_PREDICATE_METHODS = new Set(['isNull', 'isNotNull', 'isUndefined', 'isNotUndefined'])

export const getNullishPredicateMember = (node: unknown): string | null => {
  if (
    !Predicate.isObject(node) ||
    !Predicate.isObject(node.object) ||
    node.object.type !== 'Identifier' ||
    node.object.name !== 'Predicate' ||
    !Predicate.isObject(node.property) ||
    node.property.type !== 'Identifier' ||
    !Predicate.isString(node.property.name)
  ) {
    return null
  }
  const { name } = node.property
  return NULLISH_PREDICATE_METHODS.has(name) ? name : null
}

const rule: Rule = {
  create(context: Context) {
    return {
      MemberExpression(node: unknown) {
        if (!isReportable(node)) {
          return
        }
        const method = getNullishPredicateMember(node)
        if (Predicate.isNullish(method)) {
          return
        }
        const recommended = method.startsWith('isNot') ? 'isNotNullish' : 'isNullish'
        context.report({
          message: `Use Predicate.${recommended} to treat null and undefined uniformly. Only when distinguishing them is required, disable this rule with an oxlint-disable comment that includes the reason.`,
          node,
        })
      },
    }
  },
  meta: {
    type: 'suggestion',
  },
}

export default rule
