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
