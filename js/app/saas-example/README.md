# saas-example

Full-stack SaaS demo application showcasing modern React ecosystem with TanStack stack.

## Tech Stack

- **Frontend**: React 19 + TanStack Start (Router, Query, Store, Form, DB)
- **Backend**: Hono on Cloudflare Workers
- **Auth**: better-auth
- **Database**: Kysely + LibSQL
- **i18n**: Inlang Paraglide-JS (Japanese, English)
- **Styling**: Tailwind CSS v4 + @package/ui
- **Testing**: Vitest
- **Components**: Storybook
- **Build**: Vite + @cloudflare/vite-plugin
- **React Compiler**: babel-plugin-react-compiler

## Development

```bash
# Start development server
vp run dev

# Build
vp run build

# Preview built application
vp run preview

# Run tests
vp run test

# Storybook development
vp run storybook:dev

# Storybook build
vp run storybook:build
```

### Prebuild Steps

Prebuild runs automatically via Vite+ before build/check/test:

- `prebuild:cloudflare` - Generate Cloudflare Worker types
- `prebuild:paraglide` - Compile i18n messages
- `prebuild:tsr` - Generate TanStack Router route tree

## Architecture

- `src/entry.worker.ts` - Cloudflare Worker entry point
- `src/entry.hono.ts` - Hono server initialization
- `src/router.tsx` - TanStack Router configuration
- `src/routes/` - File-based route definitions
- `src/api/` - API endpoints
- `src/feature/` - Feature modules (auth, db, i18n, share)
- `messages/` - i18n translation files
- `db/` - Database schema (Atlas)

Path alias: `#@/*` maps to `./src/*`
