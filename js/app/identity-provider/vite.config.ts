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
    kysely: ['app/feature/db/generated.ts'],
  },
})

// @cloudflare/vite-plugin rejects resolve.external injected by Vite+ in vitest mode.
// Unit tests use mocked services (no live bindings) so the plugin is not needed.
const isTest = Boolean(process.env.VITEST)

export default defineConfig({
  plugins: [
    remix({ clientEntry: 'app/assets/entry.ts' }),
    ...(isTest ? [] : [cloudflare({ viteEnvironment: { name: 'ssr' } })]),
  ],
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
        dependsOn: ['setup:cloudflare', 'setup:kysely'],
      },
      'setup:cloudflare': {
        command: 'wrangler types',
        input: taskInput.setup.cloudflare,
      },
      'setup:kysely': {
        command:
          'mkdir -p app/feature/db && go run github.com/totto2727-org/monorepo/go/app/atlas-to-kysely@22cc648211cc6a73d004eb332c12d78a021ba4ec -i db/schema.hcl -o app/feature/db/generated.ts --camel-case',
        input: taskInput.setup.kysely,
      },
    },
  },
})
