import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { hasProperty, isEqualityOperator, isReportable } from '../helpers.ts'

const tagToPredicateMap: Record<string, string> = {
  None: 'Option.isNone',
  Some: 'Option.isSome',
}

export const getOptionTag = (node: unknown): string | null => {
  if (Predicate.isObject(node) && node.type === 'Literal' && Predicate.isString(node.value)) {
    const { value } = node
    if (value in tagToPredicateMap) {
      return value
    }
  }
  return null
}

export const isTagPropertyAccess = (node: unknown): boolean =>
  Predicate.isObject(node) &&
  node.type === 'MemberExpression' &&
  node.computed !== true &&
  Predicate.isObject(node.property) &&
  node.property.type === 'Identifier' &&
  node.property.name === '_tag'

const isTypeofTag = (node: unknown): boolean =>
  Predicate.isObject(node) &&
  node.type === 'UnaryExpression' &&
  node.operator === 'typeof' &&
  isTagPropertyAccess(node.argument)

const rule: Rule = {
  create(context: Context) {
    return {
      BinaryExpression(node: unknown) {
        if (!isReportable(node)) {
          return
        }
        if (Predicate.isObject(node) && isEqualityOperator(node.operator)) {
          const leftTag = getOptionTag(node.left)
          const rightTag = getOptionTag(node.right)
          const tag = leftTag ?? rightTag

          if (Predicate.isNullish(tag)) {
            return
          }

          const otherSide = Predicate.isNotNullish(leftTag) ? node.right : node.left
          if (isTagPropertyAccess(otherSide) || isTypeofTag(otherSide)) {
            const predicateFn = tagToPredicateMap[tag]
            const isEquality = node.operator === '==' || node.operator === '==='

            context.report({
              fix(fixer) {
                const rawTarget = hasProperty(otherSide, 'object') ? otherSide.object : otherSide
                if (!isReportable(rawTarget)) {
                  return null
                }
                const sourceText = context.sourceCode.getText(rawTarget)
                const prefix = isEquality ? '' : '!'
                return fixer.replaceText(node, `${prefix}${predicateFn}(${sourceText})`)
              },
              message: `Use ${predicateFn}() instead of _tag === '${tag}'`,
              node,
            })
          }
        }
      },
    }
  },
  meta: {
    fixable: 'code',
    type: 'problem',
  },
}

export default rule
