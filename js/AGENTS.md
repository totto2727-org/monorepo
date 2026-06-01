# js

## Commands

JavaScript root tasks are Vite+ tasks defined in the repository-root `vite.config.ts`.

```bash
vp run js:check # JavaScript format / lint / type check
vp run js:fix   # JavaScript auto-fix, then type check
vp run js:test  # JavaScript tests
```

## Vite+ Test Commands

Use Vite+ test helpers for file-level JavaScript and TypeScript test runs:

```bash
vp test run <test-file> # Run a specific test file
vp test related <source> # Run tests related to a source file
```
