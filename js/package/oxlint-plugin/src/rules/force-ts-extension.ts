import type { Context, Rule } from '@oxlint/plugins'
import { Predicate } from 'effect'

import { hasProperty, isReportable } from '../helpers.ts'

const JS_IMPORT_RE = /^(\.+|#(?!#)[^/]*)(\/.*)\.js(x?)$/u

export const matchJsImport = (value: string): { path: string; start: string; x: string } | null => {
  const match = JS_IMPORT_RE.exec(value)
  if (Predicate.isNotNullish(match)) {
    const [, start, path, x] = match
    return { path: path ?? '', start: start ?? '', x: x ?? '' }
  }
  return null
}

const rule: Rule = {
  create(context: Context) {
    const check = (node: unknown): void => {
      if (
        Predicate.isObject(node) &&
        hasProperty(node, 'source') &&
        Predicate.isNotNullish(node.source) &&
        hasProperty(node.source, 'raw') &&
        hasProperty(node.source, 'value')
      ) {
        const { source } = node
        const { raw, value } = source
        if (Predicate.isString(value) && Predicate.isString(raw)) {
          const matched = matchJsImport(value)
          if (Predicate.isNotNullish(matched)) {
            const { path, start, x } = matched
            const fixed = `${start}${path}.ts${x}`
            const [quote] = raw

            if (!isReportable(source)) {
              return
            }
            context.report({
              fix(fixer) {
                return fixer.replaceText(source, `${quote}${fixed}${quote}`)
              },
              message: `Use .ts${x} extension instead of .js${x}`,
              node: source,
            })
          }
        }
      }
    }

    return {
      ExportAllDeclaration: check,
      ExportNamedDeclaration: check,
      ImportDeclaration: check,
    }
  },
  meta: {
    fixable: 'code',
    type: 'problem',
  },
}

export default rule
