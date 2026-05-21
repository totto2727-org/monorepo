import { cloudflare } from '@cloudflare/vite-plugin'
import { defineTaskInputFromOutput } from '@totto2727/fp/vite'
import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite-plus'

// `setup:cloudflare` は wrangler types で `worker-configuration.d.ts` を生成する。
// design.md B-4 の規約に従い、build → setup の依存関係でビルド前に型生成を保証する。
const taskInput = defineTaskInputFromOutput({
  setup: {
    cloudflare: ['.wrangler/**', 'worker-configuration.d.ts'],
  },
})

// @cloudflare/vite-plugin rejects resolve.external injected by Vite+ in vitest mode.
// Unit tests do not need live Cloudflare bindings, so skip the plugin for tests.
const isTest = Boolean(process.env.VITEST)

export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' }), ...(isTest ? [] : [cloudflare()])],
  run: {
    tasks: {
      build: {
        command: 'vp build',
        dependsOn: ['setup'],
        input: taskInput.build,
      },
      check: {
        command: 'vp check',
        dependsOn: ['setup'],
      },
      setup: {
        command: '',
        dependsOn: ['setup:cloudflare'],
      },
      'setup:cloudflare': {
        command: 'wrangler types',
        input: taskInput.setup.cloudflare,
      },
    },
  },
})
