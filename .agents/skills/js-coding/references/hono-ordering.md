# Hono Middleware Ordering

> Document type: concrete TypeScript implementation guidance.

## Middleware Order

1. `contextStorage()` — async-local context access (must be first)
2. Runtime middleware — injects Effect runtime into `c.var.runtime`
3. Logging / other Hono middleware
4. Route-specific sub-apps and middleware
