import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { hasProperty, isReportable } from '../helpers.ts'

const ERROR_MESSAGE_INSTANCEOF_GUIDANCE =
  'Use an app-local errorMessageOrDefault() helper instead of inline `error instanceof Error ? error.message : ...` handling.'

const getIdentifierName = (node: unknown): string | null =>
  Predicate.isObject(node) && node.type === 'Identifier' && Predicate.isString(node.name) ? node.name : null

const isErrorIdentifier = (node: unknown): boolean => getIdentifierName(node) === 'Error'

const getInstanceofErrorIdentifier = (node: unknown): string | null => {
  if (
    Predicate.isObject(node) &&
    node.type === 'BinaryExpression' &&
    node.operator === 'instanceof' &&
    isErrorIdentifier(node.right)
  ) {
    return getIdentifierName(node.left)
  }
  return null
}

const isIdentifierMessageAccess = (node: unknown, identifier: string): boolean =>
  Predicate.isObject(node) &&
  node.type === 'MemberExpression' &&
  node.computed !== true &&
  Predicate.isObject(node.object) &&
  getIdentifierName(node.object) === identifier &&
  Predicate.isObject(node.property) &&
  getIdentifierName(node.property) === 'message'

export const isInstanceofErrorMessageConditional = (node: unknown): boolean => {
  if (!Predicate.isObject(node) || node.type !== 'ConditionalExpression') {
    return false
  }
  const identifier = hasProperty(node, 'test') ? getInstanceofErrorIdentifier(node.test) : null
  return Predicate.isNotNullish(identifier) && hasProperty(node, 'consequent')
    ? isIdentifierMessageAccess(node.consequent, identifier)
    : false
}

const rule: Rule = {
  create(context: Context) {
    return {
      ConditionalExpression(node: unknown) {
        if (!isReportable(node) || !isInstanceofErrorMessageConditional(node)) {
          return
        }
        context.report({ message: ERROR_MESSAGE_INSTANCEOF_GUIDANCE, node })
      },
    }
  },
  meta: {
    type: 'problem',
  },
}

export default rule
