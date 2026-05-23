import { fileURLToPath } from 'node:url'

type Severity = 'allow' | 'deny' | 'error' | 'off' | 'warn'
type RuleEntry = Severity | [Severity, ...unknown[]]
type RuleMap = Record<string, RuleEntry>

interface Preset {
  jsPlugins: string[]
  overrides: { files: string[]; rules: RuleMap }[]
  rules: RuleMap
}

const pluginPath = fileURLToPath(new URL('index.ts', import.meta.url))

const preset: Preset = {
  jsPlugins: [pluginPath],
  overrides: [
    {
      files: ['**/*.test.ts', '**/*.spec.ts'],
      rules: {
        'rules/no-let': 'allow',
        'rules/no-sync-decode': 'allow',
        'rules/prefer-is-nullish': 'allow',
        'rules/prefer-non-unknown-decode': 'allow',
        'rules/require-top-level-decoder': 'allow',
      },
    },
    {
      files: ['**/*.gen.ts'],
      rules: {
        'rules/no-redundant-alias': 'allow',
      },
    },
  ],
  rules: {
    'rules/force-array-empty': 'error',
    'rules/force-iterable-empty': 'error',
    'rules/force-predicate': 'error',
    'rules/force-string-empty': 'error',
    'rules/force-ts-extension': 'error',
    'rules/no-effect-import-as': 'error',
    'rules/no-effect-subpath-import': 'error',
    'rules/no-eslint-disable-comments': 'error',
    'rules/no-fetch': 'error',
    'rules/no-js-date': 'error',
    'rules/no-let': 'error',
    'rules/no-option-tag-comparison': 'error',
    'rules/no-redundant-alias': 'error',
    'rules/no-string-style': 'error',
    'rules/no-sync-decode': 'error',
    'rules/prefer-is-nullish': 'error',
    'rules/prefer-non-unknown-decode': 'error',
    'rules/require-disable-reason': 'error',
    'rules/require-top-level-decoder': 'error',
  },
}

export default preset
