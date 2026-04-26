import core from 'ultracite/oxlint/core'
import react from 'ultracite/oxlint/react'
import remix from 'ultracite/oxlint/remix'
import { defineConfig } from 'vite-plus'

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
    extends: [core, react, remix],
    ignorePatterns: ['**/__fixtures__/**', '**/.script/**', '**/skills/**'],
    jsPlugins: ['./js/package/oxlint-plugin/src/index.ts'],
    options: {
      typeAware: true,
      typeCheck: true,
    },
    overrides: [
      {
        files: ['**/*.test.ts', '**/*.spec.ts'],
        rules: {
          'rules/no-let': 'allow',
          'rules/no-sync-decode': 'allow',
          'rules/prefer-is-nullish': 'allow',
          'rules/prefer-non-unknown-decode': 'allow',
        },
      },
    ],
    rules: {
      'func-names': ['error', 'always', { generators: 'never' }],
      'import/extensions': ['error', 'always', { checkTypeImports: true, ignorePackages: true }],
      'jsx-no-new-function-as-prop': 'allow',
      'no-nodejs-modules': 'allow',
      'number-literal-case': 'allow',
      'rules/force-predicate': 'error',
      'rules/force-ts-extension': 'error',
      'rules/no-eslint-disable-comments': 'error',
      'rules/no-let': 'error',
      'rules/no-option-tag-comparison': 'error',
      'rules/no-sync-decode': 'error',
      'rules/prefer-is-nullish': 'warn',
      'rules/prefer-non-unknown-decode': 'warn',
      'typescript/promise-function-async': 'allow',
    },
  },
  staged: {
    '*': 'vp run fix',
  },
})
