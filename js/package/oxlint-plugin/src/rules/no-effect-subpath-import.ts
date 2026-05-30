import type { Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { hasProperty, isReportable } from '../helpers.ts'

const EFFECT_ECOSYSTEM_RE = /^@?effect(?:\/|$)/u

export const isAllowedEffectImport = (source: string): boolean => {
  if (source === 'effect') {
    return true
  }
  if (/^@effect\/[^/]+$/u.test(source)) {
    return true
  }
  if (/^effect\/unstable\/[^/]+$/u.test(source)) {
    return true
  }
  return false
}

const rule: Rule = {
  create(context) {
    return {
      ImportDeclaration(node: unknown) {
        if (!isReportable(node)) {
          return
        }
        if (!Predicate.isObject(node)) {
          return
        }
        if (!hasProperty(node, 'source')) {
          return
        }
        const { source } = node
        if (!Predicate.isObject(source)) {
          return
        }
        if (!hasProperty(source, 'value')) {
          return
        }
        if (!Predicate.isString(source.value)) {
          return
        }
        if (!EFFECT_ECOSYSTEM_RE.test(source.value)) {
          return
        }
        if (isAllowedEffectImport(source.value)) {
          return
        }
        context.report({
          message: `Avoid subpath imports from the effect ecosystem. Import from the package root instead (e.g. \`@effect/platform-node\` not \`@effect/platform-node/NodeRuntime\`).`,
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
