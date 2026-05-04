import core from 'ultracite/oxlint/core'
import react from 'ultracite/oxlint/react'
import remix from 'ultracite/oxlint/remix'
import { defineConfig } from 'vite-plus'

import oxlintPluginPreset from './js/package/oxlint-plugin/src/preset.ts'

export default defineConfig({
  fmt: {
    arrowParens: 'always',
    bracketSameLine: false,
    bracketSpacing: true,
    endOfLine: 'lf',
    experimentalSortImports: {
      ignoreCase: true,
      newlinesBetween: true,
      order: 'asc',
    },
    experimentalSortPackageJson: true,
    extends: [core, react, remix],
    jsxSingleQuote: true,
    printWidth: 120,
    quoteProps: 'as-needed',
    semi: false,
    singleQuote: true,
    tabWidth: 2,
    trailingComma: 'all',
    useTabs: false,
  },
  lint: {
    extends: [core, react, remix, oxlintPluginPreset],
    ignorePatterns: ['**/__fixtures__/**', '**/.script/**', '**/skills/**'],
    options: {
      typeAware: true,
      typeCheck: true,
    },
    rules: {
      'func-names': ['error', 'always', { generators: 'never' }],
      'import/extensions': ['error', 'always', { checkTypeImports: true, ignorePackages: true }],
      'jsx-no-new-function-as-prop': 'allow',
      'no-nodejs-modules': 'allow',
      'number-literal-case': 'allow',
      'typescript/promise-function-async': 'allow',
    },
  },
  run: {
    tasks: {
      check: {
        command: 'vp check',
      },
      fix: {
        command: 'vp check --fix',
      },
      test: {
        command: 'vp test',
      },
    },
  },
  staged: {
    '*': 'vp run fix',
  },
})
