import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { getImportSource, hasProperty, isReportable } from '../helpers.ts'

const NODE_PROTOCOL = 'node:'
const NODE_IMPORT_GUIDANCE_MESSAGE =
  'Avoid Node.js built-in imports. Prefer Effect Platform APIs from `effect` / `@effect/platform-node`; add a rule whitelist entry only for documented exceptions.'

export const getNodeBuiltinSpecifier = (source: string): string | null => {
  if (!source.startsWith(NODE_PROTOCOL)) {
    return null
  }
  return source.slice(NODE_PROTOCOL.length)
}

const getStringArrayProperty = (value: unknown, key: string): readonly string[] => {
  if (!Predicate.isObject(value) || !hasProperty(value, key) || !Array.isArray(value[key])) {
    return []
  }
  return value[key].filter(Predicate.isString)
}

const getContextOptions = (context: Context): readonly unknown[] => {
  if (!Predicate.isObject(context) || !hasProperty(context, 'options')) {
    return []
  }
  const { options } = context
  return Array.isArray(options) ? options : []
}

export const getAllowedNodeBuiltins = (context: Context): ReadonlySet<string> => {
  const options = getContextOptions(context)
  const first = options.at(0)
  if (Array.isArray(first)) {
    return new Set(first.filter(Predicate.isString))
  }
  return new Set([...getStringArrayProperty(first, 'allow'), ...getStringArrayProperty(first, 'allowed')])
}

const reportNodeImport = (node: unknown, context: Context): void => {
  const source = getImportSource(node)
  if (Predicate.isNullish(source) || !isReportable(node)) {
    return
  }
  const builtin = getNodeBuiltinSpecifier(source)
  if (Predicate.isNullish(builtin) || getAllowedNodeBuiltins(context).has(builtin)) {
    return
  }
  context.report({ message: NODE_IMPORT_GUIDANCE_MESSAGE, node })
}

const rule: Rule = {
  create(context: Context) {
    return {
      ExportAllDeclaration(node: unknown) {
        reportNodeImport(node, context)
      },
      ExportNamedDeclaration(node: unknown) {
        reportNodeImport(node, context)
      },
      ImportDeclaration(node: unknown) {
        reportNodeImport(node, context)
      },
    }
  },
  meta: {
    schema: [
      {
        anyOf: [
          { items: { type: 'string' }, type: 'array' },
          {
            additionalProperties: false,
            properties: {
              allow: { items: { type: 'string' }, type: 'array' },
              allowed: { items: { type: 'string' }, type: 'array' },
            },
            type: 'object',
          },
        ],
      },
    ],
    type: 'problem',
  },
}

export default rule
