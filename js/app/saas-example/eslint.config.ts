import gitignore from 'eslint-config-flat-gitignore'
import reactHooks from 'eslint-plugin-react-hooks'
import { defineConfig } from 'eslint/config'
import tseslint from 'typescript-eslint'

export default defineConfig([
  {
    files: ['app/**/*.{js,jsx,ts,tsx}'],
  },
  gitignore(),
  tseslint.configs.base,
  reactHooks.configs.flat['recommended-latest'],
  {
    rules: {
      'react-hooks/exhaustive-deps': [
        'warn',
        {
          enableDangerousAutofixThisMayCauseInfiniteLoops: true,
        },
      ],
    },
  },
])
