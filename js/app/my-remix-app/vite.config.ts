import { cloudflare } from '@cloudflare/vite-plugin'
import { defineConfig } from 'vite-plus'

export default defineConfig({
  plugins: [cloudflare()],
  environments: {
    client: {
      build: {
        manifest: true,
        outDir: 'dist/client',
        rollupOptions: {
          input: 'app/assets/entry.ts',
          output: {
            entryFileNames: 'assets/entry.js',
            chunkFileNames: 'assets/[name]-[hash].js',
            assetFileNames: 'assets/[name]-[hash][extname]',
          },
        },
      },
    },
  },
  builder: {
    async buildApp(builder) {
      const client = builder.environments.client
      if (client) await builder.build(client)
      for (const [name, env] of Object.entries(builder.environments)) {
        if (name === 'client') continue
        await builder.build(env)
      }
    },
  },
})
