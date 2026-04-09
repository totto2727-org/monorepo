/** @import { Rule } from 'eslint' */

/** @type {Rule.RuleModule} */
const rule = {
  create(context) {
    /**
     * @param {Rule.Node} node - AST node to check for .js/.jsx import source
     */
    const check = (node) => {
      if (!('source' in node) || !node.source) {
        return
      }
      /** @type {import('estree').Literal} */
      const { source } = node
      const { raw, value } = source
      if (typeof value !== 'string' || typeof raw !== 'string') {
        return
      }

      const match = value.match(/^(\.*|#(?!#).*)(\/.*)\.js(x?)$/)
      if (!match) {
        return
      }

      const { 1: start, 2: path, 3: x } = match
      const fixed = `${start}${path}.ts${x}`
      const [quote] = raw

      context.report({
        fix(fixer) {
          return fixer.replaceText(source, `${quote}${fixed}${quote}`)
        },
        message: `Use .ts${x} extension instead of .js${x}`,
        node: source,
      })
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

const plugin = {
  meta: { name: 'force-ts-extension' },
  rules: { 'force-ts-extension': rule },
}

export default plugin
