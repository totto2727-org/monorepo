type Severity = 'allow' | 'deny' | 'error' | 'off' | 'warn'
type RuleEntry = Severity | [Severity, ...unknown[]]
type RuleMap = Record<string, RuleEntry>

interface Preset {
  jsPlugins: string[]
  overrides: { files: string[]; rules: RuleMap }[]
  rules: RuleMap
}

const pluginPath = decodeURIComponent(new URL('index.ts', import.meta.url).pathname)

const preset: Preset = {
  jsPlugins: [pluginPath],
  overrides: [
    {
      files: ['**/*.test.ts', '**/*.spec.ts', '**/_test-helper.ts'],
      rules: {
        'rules/no-effect-runtime-run': 'allow',
        'rules/no-let': 'allow',
        'rules/no-node-imports': 'allow',
        'rules/no-sync-decode': 'allow',
        'rules/no-type-predicate': 'allow',
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
    'rules/no-effect-runtime-run': 'error',
    'rules/no-effect-subpath-import': 'error',
    'rules/no-error-cause-option': 'error',
    'rules/no-error-property-access': 'error',
    'rules/no-eslint-disable-comments': 'error',
    'rules/no-fetch': 'error',
    'rules/no-instanceof-error': 'error',
    'rules/no-js-date': 'error',
    'rules/no-jsx-script-tag': 'error',
    'rules/no-let': 'error',
    'rules/no-node-imports': [
      'error',
      {
        allow: ['child_process', 'crypto', 'os', 'util'],
      },
    ],
    'rules/no-option-tag-comparison': 'error',
    'rules/no-raw-hono-create-middleware': 'error',
    'rules/no-redundant-alias': 'error',
    'rules/no-string-style': 'error',
    'rules/no-sync-decode': 'error',
    'rules/no-type-predicate': 'error',
    'rules/prefer-is-nullish': 'error',
    'rules/prefer-non-unknown-decode': 'error',
    'rules/require-disable-reason': 'error',
    'rules/require-top-level-decoder': 'error',
  },
}

export default preset
