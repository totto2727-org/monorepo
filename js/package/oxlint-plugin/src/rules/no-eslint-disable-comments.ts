import type { Rule } from '@oxlint/plugins'

const ESLINT_DISABLE_RE = /^\s*eslint-disable(?:-next-line|-line)?\b/gm

// Exported for testing only — uses a fresh RegExp instance to avoid lastIndex side-effects
export const matchesEslintDisable = (value: string): boolean => /^\s*eslint-disable(?:-next-line|-line)?\b/m.test(value)

const rule: Rule = {
  create(context) {
    return {
      'Program:exit'() {
        const comments = context.sourceCode.getAllComments()
        for (const comment of comments) {
          const { value } = comment
          ESLINT_DISABLE_RE.lastIndex = 0
          if (ESLINT_DISABLE_RE.test(value)) {
            const fixed = value.replaceAll('eslint-disable', 'oxlint-disable')
            context.report({
              fix(fixer) {
                const [start, end] = comment.range
                const prefix = comment.type === 'Block' ? '/*' : '//'
                const suffix = comment.type === 'Block' ? '*/' : ''
                return fixer.replaceTextRange([start, end], `${prefix}${fixed}${suffix}`)
              },
              message: 'Use oxlint-disable instead of eslint-disable.',
              node: comment,
            })
          }
        }
      },
    }
  },
  meta: {
    fixable: 'code',
    type: 'problem',
  },
}

export default rule
