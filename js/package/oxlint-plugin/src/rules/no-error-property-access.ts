import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { isReportable } from '../helpers.ts'

const NO_ERROR_PROPERTY_ACCESS_MESSAGE =
  'Do not access properties on caught error values (`e`, `error`, `c`, `cause`, or `err`). Pass the value through as `error` unchanged.'

const ERROR_VALUE_NAMES = new Set(['c', 'cause', 'e', 'err', 'error'])

const getIdentifierName = (node: unknown): string | null =>
  Predicate.isObject(node) && node.type === 'Identifier' && Predicate.isString(node.name) ? node.name : null

export const isErrorPropertyAccess = (node: unknown): boolean =>
  Predicate.isObject(node) &&
  node.type === 'MemberExpression' &&
  Predicate.isObject(node.object) &&
  ERROR_VALUE_NAMES.has(getIdentifierName(node.object) ?? '')

const rule: Rule = {
  create(context: Context) {
    return {
      MemberExpression(node: unknown) {
        if (!isReportable(node) || !isErrorPropertyAccess(node)) {
          return
        }
        context.report({ message: NO_ERROR_PROPERTY_ACCESS_MESSAGE, node })
      },
    }
  },
  meta: {
    type: 'problem',
  },
}

export default rule
