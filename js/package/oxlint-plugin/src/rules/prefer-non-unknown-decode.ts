import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { isReportable, isSchemaMethodCall } from '../helpers.ts'

const UNKNOWN_DECODE_METHODS: Record<string, string> = {
  decodeUnknownEffect: 'decodeEffect',
  decodeUnknownExit: 'decodeExit',
}

export const isSchemaUnknownDecodeCall = (node: unknown): string | null => {
  for (const method of Object.keys(UNKNOWN_DECODE_METHODS)) {
    if (isSchemaMethodCall(node, method)) {
      return method
    }
  }
  return null
}

const rule: Rule = {
  create(context: Context) {
    return {
      CallExpression(node: unknown) {
        if (!isReportable(node)) {
          return
        }
        const method = isSchemaUnknownDecodeCall(node)
        if (Predicate.isNotNullish(method)) {
          const recommended = UNKNOWN_DECODE_METHODS[method]
          context.report({
            message: `Prefer Schema.${recommended} over Schema.${method}. Use unknown variants only when input type is truly unknown. Add an oxlint-disable comment if the unknown variant is required.`,
            node,
          })
        }
      },
    }
  },
  meta: {
    type: 'suggestion',
  },
}

export default rule
