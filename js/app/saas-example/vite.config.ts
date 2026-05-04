import { cloudflare } from '@cloudflare/vite-plugin'
import { paraglideVitePlugin } from '@inlang/paraglide-js'
import tailwindcss from '@tailwindcss/vite'
import { devtools } from '@tanstack/devtools-vite'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import { defineTaskInputFromOutput } from '@totto2727/fp/vite'
import viteReact from '@vitejs/plugin-react'
import { defineConfig } from 'vite-plus'

const taskInput = defineTaskInputFromOutput({
  setup: {
    cloudflare: ['.wrangler/**', 'worker-configuration.d.ts'],
    kysely: ['src/feature/db/generated.ts'],
    paraglide: ['src/feature/i18n/paraglide/**'],
    tsr: ['.tanstack/**', 'src/routeTree.gen.ts'],
  },
})

export default defineConfig({
  plugins: [
    cloudflare({ viteEnvironment: { name: 'ssr' } }),
    devtools(),
    paraglideVitePlugin({
      emitTsDeclarations: true,
      outdir: './src/feature/i18n/paraglide',
      project: './project.inlang',
      strategy: ['url', 'baseLocale'],
    }),
    tailwindcss(),
    tanstackStart(),
    viteReact({
      babel: {
        plugins: ['babel-plugin-react-compiler'],
      },
    }),
  ],
  run: {
    tasks: {
      build: {
        command: 'vp build',
        dependsOn: ['setup'],
        input: taskInput.build,
      },
      setup: {
        command: '',
        dependsOn: ['setup:cloudflare', 'setup:kysely', 'setup:paraglide', 'setup:tsr'],
      },
      'setup:cloudflare': {
        command: 'wrangler types',
        input: taskInput.setup.cloudflare,
      },
      'setup:kysely': {
        command:
          'go run github.com/totto2727-org/monorepo/go/app/atlas-to-kysely@0faf30b464eece8a80acdafad0f7ea0cec2f89e2 -i db/schema.hcl -o src/feature/db/generated.ts',
        input: taskInput.setup.kysely,
      },
      'setup:paraglide': {
        command:
          'paraglide-js compile --project ./project.inlang --outdir ./src/feature/i18n/paraglide --emit-ts-declarations',
        input: taskInput.setup.paraglide,
      },
      'setup:tsr': {
        command: 'tsr generate',
        input: taskInput.setup.tsr,
      },
    },
  },
})
