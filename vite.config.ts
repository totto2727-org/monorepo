import core from 'ultracite/oxlint/core'
import react from 'ultracite/oxlint/react'
import remix from 'ultracite/oxlint/remix'
import { defineConfig } from 'vite-plus'

import oxlintPluginPreset from './js/package/oxlint-plugin/src/preset.ts'

const ignorePatterns = ['**/__fixtures__/**']

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
    ignorePatterns,
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
    ignorePatterns: [...ignorePatterns, '**/skills/**', '**/.script/**'],
    options: {
      typeAware: true,
      typeCheck: true,
    },
    overrides: [
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
      'typescript/promise-function-async': 'allow',
      'unicorn/import-style': 'allow',
    },
  },
  run: {
    tasks: {
      check: {
        command: '',
        dependsOn: [
          'js:check',
          'mbt:check',
          // 'ex:check'
        ],
      },
      ci: {
        command: '',
        dependsOn: ['w:check', 'w:test', 'w:build'],
      },
      'ex:check': {
        command: '',
        dependsOn: ['ex:check:format', 'ex:check:compile'],
      },
      'ex:check:compile': {
        command: 'mix compile',
        input: [{ auto: true }, '!_build/**', '!deps/**'],
      },
      'ex:check:format': {
        command: 'mix format --check-formatted',
        input: [{ auto: true }, '!_build/**', '!deps/**'],
      },
      'ex:check:lint': {
        command: 'mix lint',
        input: [{ auto: true }, '!_build/**', '!deps/**'],
      },
      'ex:fix': {
        command: 'mix format',
        input: [{ auto: true }, '!_build/**', '!deps/**'],
      },
      'ex:test': {
        command: 'mix test',
        input: [{ auto: true }, '!_build/**', '!deps/**'],
      },
      fix: {
        command: '',
        dependsOn: [
          'js:fix',
          'mbt:fix',
          // 'ex:fix'
        ],
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
      'mbt:check': {
        command: 'moon check',
        input: [
          { auto: true },
          // これを除外しないとキャッシュできない？毎回変更している？暇なら詳細を調べること
          '!moon.work',
          '!**/_build/**',
        ],
      },
      'mbt:fix': {
        command: 'moon fmt',
        input: [
          { auto: true },
          // これを除外しないとキャッシュできない？毎回変更している？暇なら詳細を調べること
          '!moon.work',
          '!**/_build/**',
        ],
      },
      'mbt:test': {
        command: 'moon test',
        input: [
          { auto: true },
          // これを除外しないとキャッシュできない？毎回変更している？暇なら詳細を調べること
          '!moon.work',
          '!**/_build/**',
        ],
      },
      test: {
        command: '',
        dependsOn: [
          'js:test',
          'mbt:test',
          // 'ex:test'
        ],
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
    '*': 'vp run fix',
  },
  test: {
    dir: 'js/',
  },
})
