import { remix } from 'vite-plugin-remix'
import { defineConfig } from 'vite-plus'

export default defineConfig({
  plugins: [remix({ clientEntry: 'app/assets/entry.ts' })],
})
