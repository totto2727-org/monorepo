# Documentation MCP Server

A unified Model Context Protocol (MCP) server that provides multi-document technical documentation search capabilities. Runs on Cloudflare Workers and uses a unified Auto RAG with filtering for document search and AI response generation.

## Overview

- **Endpoint**: `/api/mcp`
- **Currently Supported**: Effect library documentation
- **Architecture**: Unified Auto RAG with folder-based filtering
- **Future Plans**: Expansion to React, Vue, and other technical documentation
- **Runtime**: Cloudflare Workers
- **Data Source**: Unified R2 bucket + Auto RAG

## Architecture

For detailed design documentation, please refer to:

- [System Architecture](./docs/architecture.md)
- [MCP Server Design](./docs/mcp-server.md)
- [Data Sync Design](./docs/data-sync.md)

## Production Environment Setup

The following configuration uses a unified approach where all documentation is stored in a single R2 bucket and managed by a single Auto RAG instance, with folder-based organization and filtering.

### Unified Naming Convention

All document types use unified resources:

- **R2 Bucket Name**: `mcp` (single bucket for all documents)
- **R2 Binding**: `DATA_SOURCE` (unified binding)
- **Auto RAG Name**: `mcp` (single Auto RAG instance)
- **Auto RAG Variable**: `AUTO_RAG_NAME` (unified variable)
- **Folder Structure**: `{document-type}/filename` (e.g., `effect/`, `react/`, `vue/`)

### Cloudflare R2

Create a unified R2 bucket for storing all documentation data.

```bash
na wrangler r2 bucket create mcp
```

Add the following configuration to `wrangler.jsonc`:

```json
{
  "r2_buckets": [
    {
      "binding": "DATA_SOURCE",
      "bucket_name": "mcp"
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

Configure unified Auto RAG for all documentation search.

1. Select the created Cloudflare R2 bucket (`mcp`) and proceed
2. Proceed to the next step
3. If you have created an AI Gateway, select it; otherwise, proceed with defaults
   - Enable query rewriting
   - Enable similarity caching
4. Set the name to `mcp`
5. Add the following configuration to `wrangler.jsonc`:
   ```json
   {
     "vars": {
       "AUTO_RAG_NAME": "mcp"
     }
   }
   ```

**Filtering**: The system automatically uses folder-based filtering to ensure each search tool only searches its relevant documents (e.g., Effect tool searches only `effect/` folder).

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

**Future Tools** (when documentation is added):

- **search_ai_react**: React documentation search
- **search_ai_vue**: Vue documentation search

### Usage Examples

#### Effect Library

```
"How to use Effect Data types"
"Error handling with Effect.gen"
"Effect pipeline processing"
```

#### Adding New Documentation

To add a new documentation source:

1. **Add Type**: Update `TargetDocument` in `app/mcp/types.ts`
2. **Add Data Source**: Configure in `app/entry.workflow.ts`
3. **Add MCP Tool**: Configure in `app/entry.hono.ts`
4. **Deploy**: The system automatically creates the folder structure and filtering

Each tool automatically searches only its relevant documentation using folder-based filtering.

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
