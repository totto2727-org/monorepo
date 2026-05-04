import { boot } from 'vite-plugin-remix/client'

boot({
  components: import.meta.glob('/app/**/*.client.tsx'),
})
