import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { getLiteralNumber, isReportable } from '../helpers.ts'

const isLengthMember = (node: unknown): boolean =>
  Predicate.isObject(node) &&
  node.type === 'MemberExpression' &&
  node.computed !== true &&
  Predicate.isObject(node.property) &&
  node.property.type === 'Identifier' &&
  node.property.name === 'length'

export type EmptyKind = 'empty' | 'non-empty'

export type LiteralPosition = 'left' | 'right'

const classifyAgainstZero = (operator: string, literalPosition: LiteralPosition): EmptyKind | null => {
  if (operator === '===' || operator === '==') {
    return 'empty'
  }
  if (operator === '!==' || operator === '!=') {
    return 'non-empty'
  }
  if (operator === '>') {
    // length > 0 -> non-empty; 0 > length -> impossible (length is always >= 0)
    return literalPosition === 'right' ? 'non-empty' : null
  }
  if (operator === '<') {
    // length < 0 -> impossible; 0 < length -> non-empty
    return literalPosition === 'right' ? null : 'non-empty'
  }
  if (operator === '>=') {
    // length >= 0 -> tautology; 0 >= length -> length === 0 -> empty
    return literalPosition === 'right' ? null : 'empty'
  }
  if (operator === '<=') {
    // length <= 0 -> length === 0 -> empty; 0 <= length -> tautology
    return literalPosition === 'right' ? 'empty' : null
  }
  return null
}

const classifyAgainstOne = (operator: string, literalPosition: LiteralPosition): EmptyKind | null => {
  if (operator === '<') {
    // length < 1 -> length === 0 -> empty; 1 < length -> length >= 2, not a clean empty/non-empty check
    return literalPosition === 'right' ? 'empty' : null
  }
  if (operator === '>=') {
    // length >= 1 -> non-empty; 1 >= length -> length is 0 or 1, not a clean empty/non-empty check
    return literalPosition === 'right' ? 'non-empty' : null
  }
  if (operator === '>') {
    // length > 1 -> length >= 2, not a clean empty/non-empty check; 1 > length -> length === 0 -> empty
    return literalPosition === 'right' ? null : 'empty'
  }
  if (operator === '<=') {
    // length <= 1 -> length is 0 or 1, not a clean empty/non-empty check; 1 <= length -> non-empty
    return literalPosition === 'right' ? null : 'non-empty'
  }
  return null
}

export const classifyLengthComparison = (
  operator: string,
  literalPosition: LiteralPosition,
  literal: number,
): EmptyKind | null => {
  if (literal === 0) {
    return classifyAgainstZero(operator, literalPosition)
  }
  if (literal === 1) {
    return classifyAgainstOne(operator, literalPosition)
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
        if (!Predicate.isObject(node)) {
          return
        }
        if (!Predicate.isString(node.operator)) {
          return
        }
        const leftIsLength = isLengthMember(node.left)
        const rightIsLength = isLengthMember(node.right)
        if (!leftIsLength && !rightIsLength) {
          return
        }
        const literalPosition: LiteralPosition = leftIsLength ? 'right' : 'left'
        const literalSide = literalPosition === 'right' ? node.right : node.left
        const literal = getLiteralNumber(literalSide)
        if (Predicate.isNullish(literal)) {
          return
        }
        const kind = classifyLengthComparison(node.operator, literalPosition, literal)
        if (Predicate.isNullish(kind)) {
          return
        }
        const message =
          kind === 'empty'
            ? 'Use Array.isArrayEmpty()/Array.isReadonlyArrayEmpty() instead of .length comparison'
            : 'Use Array.isArrayNonEmpty()/Array.isReadonlyArrayNonEmpty() instead of .length comparison'
        context.report({
          message,
          node,
        })
      },
    }
  },
  meta: {
    type: 'problem',
  },
}

export default rule
