# Z AI Zread (OSS Repository Analysis)

Analyze open source GitHub repositories via the Z AI zread MCP server.

## MCP Server

- **Server name:** `plugin:totto2727:zread` (or local MCP configuration)
- **Endpoint:** `https://api.z.ai/api/mcp/zread/mcp`

## Tools

### search_doc

Search for knowledge documentation corresponding to a GitHub repository.

**Capabilities:**

- Repository knowledge and documentation
- News and recent activity
- Recent issues and pull requests
- Contributors

**Use case:** Quickly understand repository fundamentals, find relevant documentation, and check recent activity.

### get_repo_structure

Get the directory structure and file list of a GitHub repository.

**Capabilities:**

- Complete directory tree
- File listing per directory
- Module organization overview

**Use case:** Understand project layout and locate relevant files before reading them.

### read_file

Read the complete code content of specified files in a GitHub repository.

**Capabilities:**

- Full file content retrieval
- Source code analysis

**Use case:** Analyze implementation logic, review specific files, and understand code behavior.

## Tips

- Start with `search_doc` to get context before exploring structure or code
- Use `get_repo_structure` to identify key files before using `read_file`
- Minimize `read_file` calls — focus on entry points, configuration, and files relevant to the task
- Sensitive information (API keys, passwords, credentials) must not be included in queries

## Quota Limits

Usage is subject to the Z AI plan quota:

- **Lite:** 100 combined calls
- **Pro:** 1,000 combined calls
- **Max:** 4,000 combined calls

If quota is exhausted, inform the user and suggest they check their Z AI plan.
