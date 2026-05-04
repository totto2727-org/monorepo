import { cloudflare } from '@cloudflare/vite-plugin'
import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite-plus'

export default defineConfig({
  plugins: [
    remix({ browserEntry: 'app/assets/entry.ts' }),
    cloudflare(),
  ],
})
