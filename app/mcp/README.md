# Documentation MCP Server

A unified Model Context Protocol (MCP) server that provides multi-document technical documentation search capabilities. Runs on Cloudflare Workers and uses a unified Auto RAG with filtering for document search and AI response generation.

## Overview

- **Endpoint**: `/api/mcp`
- **Architecture**: Unified Auto RAG with folder-based filtering
- **Runtime**: Cloudflare Workers
- **Data Source**: R2 bucket + Auto RAG

## Architecture

For detailed design documentation, please refer to:

- [System Architecture](./docs/architecture.md)
- [MCP Server Design](./docs/mcp-server.md)
- [Data Sync Design](./docs/data-sync.md)

## Production Environment Setup

### D1, R2, KV

1. configure Pulumi ESC
   ```yaml
   values:
     ACCESS_CLIENT_ID:
       fn::secret:
     ACCESS_CLIENT_SECRET:
       fn::secret:
     ACCESS_TOKEN_URL:
       fn::secret:
     ACCESS_AUTHORIZATION_URL:
       fn::secret:
     ACCESS_JWKS_URL:
       # key endpoint
       fn::secret:
     COOKIE_ENCRYPTION_KEY:
       # `openssl rand -hex 32`
       fn::secret:
     environmentVariables:
       ACCESS_CLIENT_ID: ${ACCESS_CLIENT_ID}
       ACCESS_CLIENT_SECRET: ${ACCESS_CLIENT_SECRET}
       ACCESS_TOKEN_URL: ${ACCESS_TOKEN_URL}
       ACCESS_AUTHORIZATION_URL: ${ACCESS_AUTHORIZATION_URL}
       ACCESS_JWKS_URL: ${ACCESS_JWKS_URL}
       COOKIE_ENCRYPTION_KEY: ${COOKIE_ENCRYPTION_KEY}
   ```
2. `cd infra/cloudflare`
3. `pulumi up`
4. Update d1_database.database-id and kv_namespace.id

### Cloudflare AI Gateway

- Not required, but recommended
- We recommend creating a new one specifically for MCP
  - Enable authenticated gateway
  - Enable logging
  - Enable caching

### Cloudflare Auto RAG

Configure unified Auto RAG for all documentation search.

1. Select the created Cloudflare R2 bucket (`mcp`) and proceed
2. Proceed to the next step
3. If you have created an AI Gateway, select it; otherwise, proceed with defaults
   - Enable query rewriting
   - Enable similarity caching
4. Set the name to `mcp`

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

- **search_ai_{hoge}**

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
