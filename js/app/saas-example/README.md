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
# Start local database server (required before vp dev)
task db:dev

# Start development server (run from this directory)
vp dev

# Run a Vite+ task — `setup` and `build` are tasks defined in vite.config.ts
vp run --filter saas-example setup    # Run every setup:* in parallel and cache the outputs
vp run --filter saas-example build    # vp build — depends on setup, exclusion globs preserve cache

# Other commands
vp preview                            # Preview built application (run from this directory)
vp run --filter saas-example storybook:dev    # Storybook development (still a script)
vp run --filter saas-example storybook:build  # Storybook build (still a script)
```

### Setup Tasks

`setup` is a Vite+ task that fans out to four sub-tasks via `dependsOn`. `build` depends on `setup`, so `vp run build` (or `vp run -r build`) automatically refreshes the generated files when their inputs change. With proper input exclusions, repeated runs hit the cache:

- `setup:cloudflare` — `wrangler types` (Cloudflare Worker bindings)
- `setup:paraglide` — `paraglide-js compile` (i18n message types)
- `setup:tsr` — `tsr generate` (TanStack Router tree)
- `setup:kysely` — `atlas-to-kysely` (Kysely type definitions from Atlas schema)

`check` / `fix` / `test` are root-level tasks (`vp check` / `vp check --fix` / `vp test`) and cover this app via Vite+'s workspace lint / type-check pass — there is no per-app `check` task.

### Database Operations

The following commands can be run while `task db:dev` is running.

```bash
# Apply schema changes
task db:schema:apply

# Reset database and re-apply schema
task db:reset && task db:schema:apply

# Create a new migration
task db:migrate:diff

# Apply migrations
task db:migrate:apply
```

> **Warning**: Migration commands (`db:migrate:diff`, `db:migrate:apply`) reset the database. Make sure to back up any important data before running them.

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
