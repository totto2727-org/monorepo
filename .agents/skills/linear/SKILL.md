---
name: linear
description: Use Linear MCP tools or Symphony's linear_graphql escape hatch for Linear issue, comment, attachment, and state operations.
---

<!--
This file adapts the Apache-2.0 licensed OpenAI Symphony linear skill for this
repository's OpenCode workflow.
Original source: https://github.com/openai/symphony/tree/main/.codex/skills/linear
-->

# Linear

Use this skill when a workflow requires Linear issue updates, persistent workpad comments, attachment links, status transitions, or raw Linear GraphQL operations.

## Tool Preference

1. Prefer configured OpenCode Linear MCP tools when they cover the operation.
2. Use Symphony's injected `linear_graphql` tool only as an escape hatch during Symphony app-server sessions.
3. Do not introduce raw-token shell helpers for Linear API access.

## Workpad Rules

- Use a single persistent issue comment headed `## OpenCode Workpad` for progress and handoff notes.
- Search active, unresolved comments first and update the existing workpad when present.
- Keep workpad updates concise, reviewer-oriented, and in Japanese for human-facing collaboration.
- Do not edit the issue description for progress tracking.

## Raw GraphQL Escape Hatch

When using `linear_graphql`, send one GraphQL operation per tool call:

```json
{
  "query": "query or mutation document",
  "variables": {
    "optional": "graphql variables object"
  }
}
```

Treat a top-level `errors` array as a failed GraphQL operation even if the tool call itself completed.

## Common Operations

### Query an Issue

Start with the issue key when available:

```graphql
query IssueByKey($key: String!) {
  issue(id: $key) {
    id
    identifier
    title
    url
    state {
      id
      name
      type
    }
    project {
      id
      name
    }
    attachments {
      nodes {
        id
        title
        url
      }
    }
  }
}
```

### Query Team States

Fetch exact state ids before changing issue state:

```graphql
query IssueTeamStates($id: String!) {
  issue(id: $id) {
    id
    team {
      id
      key
      name
      states {
        nodes {
          id
          name
          type
        }
      }
    }
  }
}
```

### Update a Comment

```graphql
mutation UpdateComment($id: String!, $body: String!) {
  commentUpdate(id: $id, input: { body: $body }) {
    success
    comment {
      id
      body
    }
  }
}
```

### Create a Comment

```graphql
mutation CreateComment($issueId: String!, $body: String!) {
  commentCreate(input: { issueId: $issueId, body: $body }) {
    success
    comment {
      id
      url
    }
  }
}
```

### Move an Issue

```graphql
mutation MoveIssueToState($id: String!, $stateId: String!) {
  issueUpdate(id: $id, input: { stateId: $stateId }) {
    success
    issue {
      id
      identifier
      state {
        id
        name
      }
    }
  }
}
```

### Attach a GitHub PR

```graphql
mutation AttachGitHubPR($issueId: String!, $url: String!, $title: String) {
  attachmentLinkGitHubPR(issueId: $issueId, url: $url, title: $title, linkKind: links) {
    success
    attachment {
      id
      title
      url
    }
  }
}
```

## Upload Flow

For media uploads through raw GraphQL:

1. Call `fileUpload` to get `uploadUrl`, `assetUrl`, and required headers.
2. Upload bytes to the signed `uploadUrl` with exactly the returned headers.
3. Reference the resulting `assetUrl` in `commentCreate` or `commentUpdate`.

Use shell only for the signed upload URL; the signed URL already carries the required authorization.
