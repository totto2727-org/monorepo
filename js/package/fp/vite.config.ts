import { defineConfig } from 'vite-plus'

export default defineConfig({
  run: {
    tasks: {
      check: {
        command: '',
        dependsOn: ['check:doc', 'check:slowtype'],
      },
      'check:doc': {
        command: "deno doc --lint 'src/**/*.ts'",
      },
      'check:slowtype': {
        command: 'vpx jsr publish --dry-run --allow-dirty',
      },
    },
  },
})
