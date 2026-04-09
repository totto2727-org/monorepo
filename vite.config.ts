import { core, react, remix } from 'ultracite/oxlint'
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
    ignorePatterns: ['**/__fixtures__/**'],
    jsPlugins: ['./js/package/oxlint-plugin/src/index.ts'],
    options: {
      typeAware: true,
      typeCheck: true,
    },
    overrides: [
      {
        files: ['**/*.test.ts', '**/*.spec.ts'],
        rules: {
          'rules/no-sync-decode': 'allow',
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
      'rules/no-let': 'error',
      'rules/no-option-tag-comparison': 'error',
      'rules/no-sync-decode': 'error',
      'typescript/promise-function-async': 'allow',
    },
  },
  staged: {
    '*': 'vp run fix',
  },
})
