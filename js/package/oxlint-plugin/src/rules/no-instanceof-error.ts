import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { isReportable } from '../helpers.ts'

const NO_INSTANCEOF_ERROR_MESSAGE =
  'Do not use `instanceof Error`. Preserve caught errors as `error` and handle narrowing only in the shared fp error helper with an explicit disable comment.'

const getIdentifierName = (node: unknown): string | null =>
  Predicate.isObject(node) && node.type === 'Identifier' && Predicate.isString(node.name) ? node.name : null

export const isInstanceofError = (node: unknown): boolean =>
  Predicate.isObject(node) &&
  node.type === 'BinaryExpression' &&
  node.operator === 'instanceof' &&
  getIdentifierName(node.right) === 'Error'

const rule: Rule = {
  create(context: Context) {
    return {
      BinaryExpression(node: unknown) {
        if (!isReportable(node) || !isInstanceofError(node)) {
          return
        }
        context.report({ message: NO_INSTANCEOF_ERROR_MESSAGE, node })
      },
    }
  },
  meta: {
    type: 'problem',
  },
}

export default rule
