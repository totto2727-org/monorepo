import { boot } from 'vite-plugin-remix/client'

// Project-wide convention: any *.client.tsx is a clientEntry-bearing module.
// import.meta.glob is a compile-time syntax — the bundler must see this
// literal call here in the consumer source, so the registry stays in the
// app rather than living inside the package.
boot({
  // oxlint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call -- import.meta.glob is provided by Vite at build time; types are out-of-band.
  // @ts-expect-error -- Vite's `import.meta.glob` is not part of the standard ImportMeta type.
  components: import.meta.glob('/app/**/*.client.tsx'),
})
