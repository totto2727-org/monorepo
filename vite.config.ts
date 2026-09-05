import core from 'ultracite/oxlint/core'
import { defineConfig } from 'vite-plus'

import oxlintPluginPreset from './js/package/oxlint-plugin/src/preset.ts'

const ignorePatterns = ['**/__fixtures__/**']

export default defineConfig({
  fmt: {
    arrowParens: 'always',
    experimentalSortImports: {
      ignoreCase: true,
      newlinesBetween: true,
      order: 'asc',
    },
    experimentalSortPackageJson: true,
    ignorePatterns: [
      ...ignorePatterns,
      // oxlint-disable-next-line eslint/no-warning-comments -- This exclusion is intentionally temporary.
      // TODO: Remove this temporary exclusion once `.agents` is formatter-compatible.
      '.agents/**',
    ],
    jsxSingleQuote: true,
    printWidth: 120,
    semi: false,
    singleQuote: true,
  },
  lint: {
    extends: [
      // @ts-expect-error ignore type error for now, because the type of `extends` is not correct in `ultracite/oxlint/core`
      core,
      oxlintPluginPreset,
    ],
    ignorePatterns: [...ignorePatterns, '**/skills/**', '**/.script/**'],
    options: {
      typeAware: true,
      typeCheck: true,
    },
    overrides: [
      {
        files: ['**/SKILL.md.ts'],
        rules: {
          'unicorn/filename-case': 'off',
        },
      },
      {
        files: ['**/*.test.{ts,tsx}', '**/*_test-helper.{ts,tsx}', '**/__tests__/**/*.{ts,tsx}'],
        rules: {
          'no-await-in-loop': 'allow',
        },
      },
    ],
    rules: {
      'func-names': ['error', 'always', { generators: 'never' }],
      'import/extensions': ['error', 'always', { checkTypeImports: true, ignorePackages: true }],
      'jsx-no-new-function-as-prop': 'allow',
      'no-nodejs-modules': 'allow',
      'node/callback-return': 'allow',
      'number-literal-case': 'allow',
      'promise/prefer-await-to-then': 'allow',
      'typescript/promise-function-async': 'allow',
      'unicorn/import-style': 'allow',
    },
  },
  run: {
    tasks: {
      check: {
        command: '',
        dependsOn: ['js:check'],
      },
      ci: {
        command: '',
        dependsOn: ['w:check', 'w:test', 'w:build'],
      },
      fix: {
        command: '',
        dependsOn: ['js:fix'],
      },
      'js:check': {
        command: 'vp check',
      },
      'js:fix': {
        command: 'vp check --fix',
      },
      'js:test': {
        command: 'vp test',
      },
      test: {
        command: '',
        dependsOn: ['js:test'],
      },
      'w:build': {
        command: 'vp run -r build',
        dependsOn: ['w:setup'],
      },
      'w:check': {
        command: 'vp run -r check',
        dependsOn: ['w:setup'],
      },
      'w:fix': {
        command: 'vp run -r fix',
        dependsOn: ['w:setup'],
      },
      'w:setup': {
        command: 'vp run -r setup',
      },
      'w:test': {
        command: 'vp run -r test',
        dependsOn: ['w:setup'],
      },
    },
  },
  staged: {
    '*': 'treefmt',
  },
  test: {
    dir: 'js/',
  },
})
