import { defineTaskInputFromOutput } from '@totto2727/fp/vite'
import { defineConfig } from 'vite-plus'

const taskInput = defineTaskInputFromOutput({
  setup: {
    'cloudflare:bff': ['.wrangler/**', 'src/worker/bff/worker-configuration.d.ts'],
    'cloudflare:health': ['.wrangler/**', 'src/worker/health/worker-configuration.d.ts'],
  },
})

export default defineConfig({
  run: {
    tasks: {
      build: {
        // backend は wrangler 直接 deploy 時にビルドされるため、ここでは no-op に設定。
        // SC-4 (`vp run -r build`) が backend を skip しないように空 command で完走させる。
        command: '',
        dependsOn: ['setup'],
      },
      setup: {
        command: '',
        dependsOn: ['setup:cloudflare:bff', 'setup:cloudflare:health'],
      },
      'setup:cloudflare:bff': {
        command: 'wrangler types --config src/worker/bff/wrangler.jsonc src/worker/bff/worker-configuration.d.ts',
        input: taskInput.setup['cloudflare:bff'],
      },
      'setup:cloudflare:health': {
        command: 'wrangler types --config src/worker/health/wrangler.jsonc src/worker/health/worker-configuration.d.ts',
        input: taskInput.setup['cloudflare:health'],
      },
    },
  },
})
