import markdownPlugin from '@textlint/textlint-plugin-markdown'
import { defineConfig } from 'mdts'
import type { TextlintRuleModule } from 'mdts'

const forbiddenWordRule: TextlintRuleModule<{ readonly word?: string }> = (context, options) => {
  const word = options?.word ?? 'forbidden'
  return {
    [context.Syntax.Str](node) {
      if (node.value.includes(word)) {
        context.report(node, new context.RuleError(`Do not use ${word}`))
      }
    },
  }
}

const writingPreset = {
  rules: {
    'no-forbidden-word': forbiddenWordRule,
  },
  rulesConfig: {
    'no-forbidden-word': {
      word: 'forbidden',
    },
  },
}

export default defineConfig({
  input: './content',
  lint: {
    markdownlint: {
      config: {
        default: false,
        MD013: {
          line_length: 150,
        },
      },
    },
    textlint: {
      plugins: [{ plugin: markdownPlugin, pluginId: 'markdown' }],
      presets: [{ preset: writingPreset, presetId: 'writing' }],
    },
  },
  output: './dist',
  vite: {
    logLevel: 'silent',
  },
})
