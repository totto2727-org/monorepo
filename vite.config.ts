import core from 'ultracite/oxlint/core'
import react from 'ultracite/oxlint/react'
import remix from 'ultracite/oxlint/remix'
import { defineConfig } from 'vite-plus'

import oxlintPluginPreset from './js/package/oxlint-plugin/src/preset.ts'

const ignorePatterns = ['**/__fixtures__/**', '**/.factory/settings.json']

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
    rules: {
      'func-names': ['error', 'always', { generators: 'never' }],
      'import/extensions': ['error', 'always', { checkTypeImports: true, ignorePackages: true }],
      'jsx-no-new-function-as-prop': 'allow',
      'no-nodejs-modules': 'allow',
      'number-literal-case': 'allow',
      'promise/prefer-await-to-then': 'allow',
      'typescript/promise-function-async': 'allow',
    },
  },
  run: {
    tasks: {
      check: {
        command: '',
        dependsOn: ['js:check', 'mbt:check'],
      },
      ci: {
        command: '',
        dependsOn: ['w:check', 'w:test', 'w:build'],
      },
      fix: {
        command: '',
        dependsOn: ['js:fix', 'mbt:fix'],
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
        input: [{ auto: true }, '!**/_build/**'],
      },
      'mbt:fix': {
        command: 'moon fmt',
        input: [{ auto: true }, '!**/_build/**'],
      },
      'mbt:test': {
        command: 'moon test',
        input: [{ auto: true }, '!**/_build/**'],
      },
      test: {
        command: '',
        dependsOn: ['js:test', 'mbt:test'],
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
