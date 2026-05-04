import { cloudflare } from '@cloudflare/vite-plugin'
import { paraglideVitePlugin } from '@inlang/paraglide-js'
import tailwindcss from '@tailwindcss/vite'
import { devtools } from '@tanstack/devtools-vite'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import viteReact from '@vitejs/plugin-react'
import { defineConfig } from 'vite-plus'

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
        dependsOn: ['prebuild'],
        input: [
          { auto: true },
          '!worker-configuration.d.ts',
          '!src/routeTree.gen.ts',
          '!src/feature/db/generated.ts',
          '!src/feature/i18n/paraglide/**',
          '!.wrangler/**',
          '!.tanstack/**',
          '!dist/**',
          { base: 'workspace', pattern: '!**/.wrangler/**' },
          { base: 'workspace', pattern: '!**/.tanstack/**' },
          { base: 'workspace', pattern: '!**/dist/**' },
          { base: 'workspace', pattern: '!**/routeTree.gen.ts' },
        ],
      },
      prebuild: {
        command: 'echo prebuild complete',
        dependsOn: ['prebuild:cloudflare', 'prebuild:kysely', 'prebuild:paraglide', 'prebuild:tsr'],
      },
      'prebuild:cloudflare': {
        command: 'wrangler types',
        input: [
          { auto: true },
          '!worker-configuration.d.ts',
          '!.wrangler/**',
          { base: 'workspace', pattern: '!**/.wrangler/**' },
        ],
      },
      'prebuild:kysely': {
        command:
          'go run github.com/totto2727-org/monorepo/go/app/atlas-to-kysely@0faf30b464eece8a80acdafad0f7ea0cec2f89e2 -i db/schema.hcl -o src/feature/db/generated.ts',
        input: [{ auto: true }, '!src/feature/db/generated.ts'],
      },
      'prebuild:paraglide': {
        command:
          'paraglide-js compile --project ./project.inlang --outdir ./src/feature/i18n/paraglide --emit-ts-declarations',
        input: [{ auto: true }, '!src/feature/i18n/paraglide/**'],
      },
      'prebuild:tsr': {
        command: 'tsr generate',
        input: [
          { auto: true },
          '!src/routeTree.gen.ts',
          '!.tanstack/**',
          { base: 'workspace', pattern: '!**/routeTree.gen.ts' },
          { base: 'workspace', pattern: '!**/.tanstack/**' },
        ],
      },
    },
  },
})
