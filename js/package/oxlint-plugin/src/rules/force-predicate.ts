import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { isEqualityOperator, isReportable } from '../helpers.ts'

const typeofToPredicateMap: Record<string, string> = {
  bigint: 'Predicate.isBigInt',
  boolean: 'Predicate.isBoolean',
  function: 'Predicate.isFunction',
  number: 'Predicate.isNumber',
  object: 'Predicate.isObject',
  string: 'Predicate.isString',
  symbol: 'Predicate.isSymbol',
  undefined: 'Predicate.isUndefined',
}

const isNullLiteral = (node: unknown): boolean =>
  Predicate.isObject(node) && node.type === 'Literal' && Predicate.isNullish(node.value)

const isUndefinedIdentifier = (node: unknown): boolean =>
  Predicate.isObject(node) && node.type === 'Identifier' && node.name === 'undefined'

export const getNullishSide = (node: unknown): 'null' | 'undefined' | null => {
  if (isNullLiteral(node)) {
    return 'null'
  }
  if (isUndefinedIdentifier(node)) {
    return 'undefined'
  }
  return null
}

export const getTypeofType = (node: unknown): 'typeof' | null => {
  if (Predicate.isObject(node) && node.type === 'UnaryExpression' && node.operator === 'typeof') {
    return 'typeof'
  }
  return null
}

export const getStringValue = (node: unknown): string | null => {
  if (Predicate.isObject(node) && node.type === 'Literal' && Predicate.isString(node.value)) {
    return node.value
  }
  return null
}

const resolveTypeStr = (
  leftTypeof: 'typeof' | null,
  rightTypeof: 'typeof' | null,
  leftStr: string | null,
  rightStr: string | null,
): string | null => {
  if (Predicate.isNotNullish(leftTypeof)) {
    return rightStr
  }
  if (Predicate.isNotNullish(rightTypeof)) {
    return leftStr
  }
  return null
}

const rule: Rule = {
  create(context: Context) {
    return {
      BinaryExpression(node: unknown) {
        if (!isReportable(node)) {
          return
        }
        if (Predicate.isObject(node) && isEqualityOperator(node.operator)) {
          const leftKind = getNullishSide(node.left)
          const rightKind = getNullishSide(node.right)
          const kind = leftKind ?? rightKind

          if (Predicate.isNotNullish(kind)) {
            const predicateFn = kind === 'null' ? 'Predicate.isNull' : 'Predicate.isUndefined'
            context.report({
              message: `Use ${predicateFn}() instead of direct ${kind} comparison`,
              node,
            })
            return
          }

          const leftTypeof = getTypeofType(node.left)
          const rightTypeof = getTypeofType(node.right)
          const leftStr = getStringValue(node.left)
          const rightStr = getStringValue(node.right)

          const typeStr = resolveTypeStr(leftTypeof, rightTypeof, leftStr, rightStr)

          if (Predicate.isNullish(typeStr)) {
            return
          }

          const predicateFn = typeofToPredicateMap[typeStr]
          if (Predicate.isNullish(predicateFn)) {
            return
          }

          context.report({
            message: `Use ${predicateFn}() instead of typeof comparison`,
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
