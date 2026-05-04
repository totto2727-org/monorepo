import { boot } from 'vite-plugin-remix/client'

// Project-wide convention: any *.client.tsx is a clientEntry-bearing module.
// import.meta.glob is a compile-time syntax — the bundler must see this
// literal call here in the consumer source, so the registry stays in the
// app rather than living inside the package.
boot({
  components: import.meta.glob('/app/**/*.client.tsx'),
})
