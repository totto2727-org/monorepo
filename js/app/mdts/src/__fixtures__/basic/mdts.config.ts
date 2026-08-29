import { defineConfig } from 'mdts'

export default defineConfig({
  input: './content',
  output: './dist',
  vite: {
    logLevel: 'silent',
    server: {
      port: 0,
      strictPort: true,
    },
  },
})
