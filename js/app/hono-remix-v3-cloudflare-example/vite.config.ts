import { cloudflare } from '@cloudflare/vite-plugin'
import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite-plus'

export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' }), cloudflare()],
  run: {
    tasks: {
      build: {
        cache: { input: [{ auto: true }, '!.wrangler/**', '!dist/**'] },
        command: 'vp build',
      },
    },
  },
})
