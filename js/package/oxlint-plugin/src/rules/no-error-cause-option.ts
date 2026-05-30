import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { hasProperty, isReportable } from '../helpers.ts'

const NO_ERROR_CAUSE_OPTION_MESSAGE = 'Do not pass `{ cause }` to `new Error`. Use `{ error }` instead.'

const getIdentifierName = (node: unknown): string | null =>
  Predicate.isObject(node) && node.type === 'Identifier' && Predicate.isString(node.name) ? node.name : null

const getPropertyKeyName = (node: unknown): string | null => {
  if (Predicate.isObject(node) && node.type === 'Identifier' && Predicate.isString(node.name)) {
    return node.name
  }
  if (Predicate.isObject(node) && node.type === 'Literal' && Predicate.isString(node.value)) {
    return node.value
  }
  return null
}

const hasCauseProperty = (node: unknown): boolean =>
  Predicate.isObject(node) &&
  node.type === 'ObjectExpression' &&
  hasProperty(node, 'properties') &&
  Array.isArray(node.properties) &&
  node.properties.some((property) =>
    Predicate.isObject(property) && hasProperty(property, 'key') ? getPropertyKeyName(property.key) === 'cause' : false,
  )

export const isNewErrorWithCauseOption = (node: unknown): boolean =>
  Predicate.isObject(node) &&
  node.type === 'NewExpression' &&
  getIdentifierName(node.callee) === 'Error' &&
  hasProperty(node, 'arguments') &&
  Array.isArray(node.arguments) &&
  node.arguments.some(hasCauseProperty)

const rule: Rule = {
  create(context: Context) {
    return {
      NewExpression(node: unknown) {
        if (!isReportable(node) || !isNewErrorWithCauseOption(node)) {
          return
        }
        context.report({ message: NO_ERROR_CAUSE_OPTION_MESSAGE, node })
      },
    }
  },
  meta: {
    type: 'problem',
  },
}

export default rule
