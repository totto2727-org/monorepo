import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { hasProperty, isReportable } from '../helpers.ts'

const FETCH_GLOBALS: ReadonlySet<string> = new Set(['globalThis', 'self', 'window'])
const FETCH_GUIDANCE_MESSAGE =
  'Use Effect `HttpClient` (provide the `FetchHttpClient` layer) instead of the global `fetch`. Bypass only at external-library anti-corruption layers with a documented disable reason.'

export const isFetchIdentifier = (node: unknown): boolean =>
  Predicate.isObject(node) && node.type === 'Identifier' && hasProperty(node, 'name') && node.name === 'fetch'

export const isFetchOnGlobal = (node: unknown): boolean => {
  if (!Predicate.isObject(node) || node.type !== 'MemberExpression' || node.computed === true) {
    return false
  }
  if (!isFetchIdentifier(node.property)) {
    return false
  }
  if (!Predicate.isObject(node.object) || node.object.type !== 'Identifier') {
    return false
  }
  return hasProperty(node.object, 'name') && Predicate.isString(node.object.name) && FETCH_GLOBALS.has(node.object.name)
}

const rule: Rule = {
  create(context: Context) {
    return {
      CallExpression(node: unknown) {
        if (!isReportable(node) || !Predicate.isObject(node) || !hasProperty(node, 'callee')) {
          return
        }
        const { callee } = node
        if (isFetchIdentifier(callee) || isFetchOnGlobal(callee)) {
          context.report({
            message: FETCH_GUIDANCE_MESSAGE,
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
