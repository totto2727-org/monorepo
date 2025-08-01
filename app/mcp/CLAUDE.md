# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Application Overview

This is an MCP (Model Context Protocol) application running on Cloudflare Workers. It uses the Hono framework and is built with Vite.

## Development Commands

**Development:**

- `nr dev` - Start Vite development server
- `nr preview` - Start Wrangler preview server
- `nr start` - Start Wrangler local development server
- `nr check` - Run TypeScript type checking

**Build & Deploy:**

- `nr build` - Build for production with Vite
- `nr deploy` - Deploy to Cloudflare Workers

## Architecture

### Project Structure

```
app/
├── entry.hono.ts    # Hono application definition
└── entry.worker.ts  # Workers entry point
```

### Tech Stack

- **Hono**: Lightweight web framework
- **Vite**: Build tool
- **Cloudflare Workers**: Serverless execution environment
- **TypeScript**: Type safety

### Cloudflare Services Integration

- **AI Binding**: Access to Cloudflare AI
- **R2 Bucket**: Data storage (`DATA_SOURCE` binding)
- **Auto RAG**: Retrieval-Augmented Generation (configured via `AUTO_RAG_NAME` environment variable)
- **Observability**: Performance monitoring enabled

### Configuration Files

- `wrangler.jsonc`: Workers configuration, bindings, environment variables
- `vite.config.ts`: Vite build configuration
- Import Maps: Clean path resolution with `#@*` prefix

### Dependency Management

- Dependencies should be added to `devDependencies` as a general rule

## Deployment

### Production Environment Setup

1. **Cloudflare R2**: Create bucket for data storage
2. **AI Gateway**: API management and caching (recommended)
3. **Auto RAG**: RAG functionality integrated with R2 bucket
4. **Workers**: GitHub integration or local deployment

Refer to README.md for detailed setup instructions.
