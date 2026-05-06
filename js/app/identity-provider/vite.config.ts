import { cloudflare } from '@cloudflare/vite-plugin'
import { defineTaskInputFromOutput } from '@totto2727/fp/vite'
import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite-plus'

// `setup:cloudflare` は wrangler types で `worker-configuration.d.ts` を生成する。
// design.md C-4 の規約に従い、build → setup の依存関係でビルド前に型生成を保証する
// (`feed-platform-web/vite.config.ts` と完全同形)。
const taskInput = defineTaskInputFromOutput({
  setup: {
    cloudflare: ['.wrangler/**', 'worker-configuration.d.ts'],
  },
})

export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' }), cloudflare()],
  run: {
    tasks: {
      build: {
        command: 'vp build',
        dependsOn: ['setup'],
        input: taskInput.build,
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
