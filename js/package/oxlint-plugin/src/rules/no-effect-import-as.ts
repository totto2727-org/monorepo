import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { getImportSource, hasProperty, isReportable } from '../helpers.ts'

const EFFECT_IMPORT_RE = /^@?effect(?:\/|$)/

export const isEffectEcosystemImport = (sourceValue: string): boolean => EFFECT_IMPORT_RE.test(sourceValue)

const checkSpecifierForAs = (
  spec: Record<string, unknown>,
  context: Context,
  reportNode: Record<string, unknown> & { range: [number, number] },
): boolean => {
  if (spec.type === 'ImportNamespaceSpecifier') {
    const localName =
      hasProperty(spec, 'local') &&
      Predicate.isObject(spec.local) &&
      hasProperty(spec.local, 'name') &&
      Predicate.isString(spec.local.name)
        ? spec.local.name
        : ''
    context.report({
      message: `Avoid namespace import (\`import * as ${localName}\`) from the effect ecosystem. Use named imports directly.`,
      node: reportNode,
    })
    return true
  }

  if (
    spec.type === 'ImportSpecifier' &&
    hasProperty(spec, 'imported') &&
    hasProperty(spec, 'local') &&
    Predicate.isObject(spec.imported) &&
    Predicate.isObject(spec.local) &&
    hasProperty(spec.imported, 'name') &&
    hasProperty(spec.local, 'name') &&
    Predicate.isString(spec.imported.name) &&
    Predicate.isString(spec.local.name)
  ) {
    const { name: importedName } = spec.imported
    const { name: localName } = spec.local
    if (importedName !== localName) {
      context.report({
        message: `Avoid aliased import (\`${importedName} as ${localName}\`) from the effect ecosystem. Import \`${importedName}\` directly without aliasing.`,
        node: reportNode,
      })
      return true
    }
  }

  return false
}

const rule: Rule = {
  create(context: Context) {
    return {
      ImportDeclaration(node: unknown) {
        const sourceValue = getImportSource(node)
        if (Predicate.isNullish(sourceValue) || !isEffectEcosystemImport(sourceValue) || !isReportable(node)) {
          return
        }
        const specifiers = Predicate.isObject(node) && hasProperty(node, 'specifiers') ? node.specifiers : null
        if (!Array.isArray(specifiers)) {
          return
        }
        for (const spec of specifiers) {
          if (Predicate.isObject(spec) && checkSpecifierForAs(spec, context, node)) {
            return
          }
        }
      },
    }
  },
  meta: {
    type: 'problem',
  },
}

export default rule
