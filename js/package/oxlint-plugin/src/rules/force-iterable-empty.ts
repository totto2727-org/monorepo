import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { getLiteralNumber, isReportable } from '../helpers.ts'
import { classifyLengthComparison } from './force-array-empty.ts'
import type { LiteralPosition } from './force-array-empty.ts'

export const isIterableSizeCall = (node: unknown): boolean =>
  Predicate.isObject(node) &&
  node.type === 'CallExpression' &&
  Predicate.isObject(node.callee) &&
  node.callee.type === 'MemberExpression' &&
  node.callee.computed !== true &&
  Predicate.isObject(node.callee.object) &&
  node.callee.object.type === 'Identifier' &&
  node.callee.object.name === 'Iterable' &&
  Predicate.isObject(node.callee.property) &&
  node.callee.property.type === 'Identifier' &&
  node.callee.property.name === 'size'

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
        const leftIsSize = isIterableSizeCall(node.left)
        const rightIsSize = isIterableSizeCall(node.right)
        if (!leftIsSize && !rightIsSize) {
          return
        }
        const literalPosition: LiteralPosition = leftIsSize ? 'right' : 'left'
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
            ? 'Use Iterable.isEmpty() instead of Iterable.size() === 0 comparison'
            : 'Use !Iterable.isEmpty() instead of Iterable.size() comparison'
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
