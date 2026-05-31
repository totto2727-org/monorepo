import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { hasProperty, isReportable } from '../helpers.ts'

const RUNTIME_METHODS: ReadonlySet<string> = new Set([
  'runCallback',
  'runFork',
  'runMain',
  'runPromise',
  'runPromiseExit',
  'runSync',
])

export const getRuntimeMethod = (node: unknown): string | null => {
  if (
    Predicate.isObject(node) &&
    node.type === 'MemberExpression' &&
    node.computed !== true &&
    Predicate.isObject(node.property) &&
    node.property.type === 'Identifier' &&
    Predicate.isString(node.property.name) &&
    RUNTIME_METHODS.has(node.property.name)
  ) {
    return node.property.name
  }
  return null
}

const isRuntimeCallee = (node: unknown): boolean => Predicate.isNotNullish(getRuntimeMethod(node))

const rule: Rule = {
  create(context: Context) {
    return {
      CallExpression(node: unknown) {
        if (!isReportable(node) || !Predicate.isObject(node) || !hasProperty(node, 'callee')) {
          return
        }
        if (!isRuntimeCallee(node.callee)) {
          return
        }
        context.report({
          message:
            'Run Effect runtimes only at workflow boundaries. Move runtime execution to the top-level entrypoint, or disable this rule with a reason for genuinely independent workflows (for example a client-side useEffect).',
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
