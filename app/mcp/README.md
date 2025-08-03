# Documentation MCP Server

A Model Context Protocol (MCP) server that provides technical documentation search capabilities. Runs on Cloudflare Workers and uses Auto RAG for document search and AI response generation.

## Overview

- **Endpoint**: `/api/mcp`
- **Currently Supported**: Effect library documentation
- **Future Plans**: Expansion to other technical documentation
- **Runtime**: Cloudflare Workers
- **Data Source**: R2 + Auto RAG

## Architecture

For detailed design documentation, please refer to:

- [System Architecture](./docs/architecture.md)
- [MCP Server Design](./docs/mcp-server.md)
- [Data Sync Design](./docs/data-sync.md)

## Production Environment Setup

The following is a configuration example for Effect documentation. When adding other document sources, create resources using similar steps.

### Naming Conventions

When adding new document sources, follow these naming patterns:

- **R2 Bucket Names**: `{library-name}-mcp` (e.g., `effect-mcp`, `react-mcp`, `vue-mcp`)
- **R2 Bindings**: `{LIBRARY_NAME}_DATA_SOURCE` (e.g., `EFFECT_DATA_SOURCE`, `REACT_DATA_SOURCE`)
- **Auto RAG Names**: `{library-name}-mcp` (e.g., `effect-mcp`, `react-mcp`, `vue-mcp`)
- **Auto RAG Variables**: `{LIBRARY_NAME}_AUTO_RAG_NAME` (e.g., `EFFECT_AUTO_RAG_NAME`, `REACT_AUTO_RAG_NAME`)

### Cloudflare R2

Create an R2 bucket for storing Effect documentation data.

```bash
na wrangler r2 bucket create effect-mcp
```

Add the following configuration to `wrangler.jsonc`:

```json
{
  "r2_buckets": [
    {
      "binding": "EFFECT_DATA_SOURCE",
      "bucket_name": "effect-mcp"
    }
  ]
}
```

**Important**: Configure R2 bucket lifecycle to automatically delete objects after 2 weeks to manage storage costs and keep data fresh.

### Cloudflare AI Gateway

- Not required, but recommended
- We recommend creating a new one specifically for MCP
  - Enable logging
  - Enable caching

TODO: Add configuration for authenticated gateway usage

### Cloudflare Auto RAG

Configure Auto RAG for Effect documentation search.

1. Select the created Cloudflare R2 bucket (`effect-mcp`) and proceed
2. Proceed to the next step
3. If you have created an AI Gateway, select it; otherwise, proceed with defaults
   - Enable query rewriting
   - Enable similarity caching
4. Set the name to `effect-mcp`
5. Add the following configuration to `wrangler.jsonc`:
   ```json
   {
     "vars": {
       "EFFECT_AUTO_RAG_NAME": "effect-mcp"
     }
   }
   ```

### Cloudflare Workers

1. Deploy from local environment
2. Connect with GitHub
   - build: `pnpm turbo build`
   - cwd: `app/mcp`
3. Configure build environment
   - Set appropriate versions
   - `NODE_VERSION`
   - `PNPM_VERSION`

## MCP Configuration

After deployment, configure the following endpoint in your MCP client (Claude Desktop or Claude Code).

### Endpoint

```
https://mcp.totto2727.workers.dev/api/mcp
```

### Claude Code Configuration

To install with user scope in Claude Code:

```bash
claude mcp add -s user --transport http totto-doc-mcp https://mcp.totto2727.workers.dev/api/mcp
```

### Available Tools

Currently supported tools:

- **search_ai_effect**: Effect documentation search and AI response generation

### Usage Examples

#### Effect Library

```
"How to use Effect Data types"
"Error handling with Effect.gen"
"Effect pipeline processing"
```

#### Future Additions

We plan to provide similar search tools for other technical documentation (React, Vue, and other libraries).

## Development

### Local Development

```bash
# Install dependencies
ni

# Start development server
nr dev

# Type checking
nr check

# Build
nr build
```

### Deployment

```bash
# Deploy to production
nr deploy
```
