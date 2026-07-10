<!--
このファイルは元のApache 2.0ライセンスのコードから変更されています
変更日: 2026-06-28
変更者: totto2727
変更内容: 冒頭に元リポジトリ（OpenAI Symphony）への帰属表示を追加し、OpenCode バックエンド前提の説明へ修正
-->

# Symphony

This directory contains the current Elixir/OTP implementation of Symphony, based on
[`SPEC.md`](docs/SPEC.md) from the original repository.

This project is a port of the original [OpenAI Symphony](https://github.com/openai/symphony).

> [!WARNING]
> Symphony is prototype software intended for evaluation only and is presented as-is.
> We recommend implementing your own hardened version based on `SPEC.md`.

## Screenshot

![Symphony screenshot](docs/media/elixir-screenshot.png)

## How it works

1. Polls Linear for candidate work
2. Creates a workspace per issue
3. Starts or connects to an OpenCode HTTP server
4. Creates an OpenCode session for the issue workspace and sends the workflow prompt
5. Keeps OpenCode working on the issue until the work is done

During app-server sessions, Symphony also serves a client-side `linear_graphql` tool so agents,
external helper skills, or workflow prompts can make raw Linear GraphQL calls.

If a claimed issue moves to a terminal state (`Done`, `Closed`, `Cancelled`, or `Duplicate`),
Symphony stops the active agent for that issue and cleans up matching workspaces.

If OpenCode reports that operator input or permission is required, Symphony keeps the
issue claimed and exposes it as blocked in the runtime state, JSON API, and dashboard. Blocked
entries are in memory only; restarting the orchestrator clears that blocked map, so any still-active
Linear issue can become a dispatch candidate again after restart.

## How to use it

1. Make sure your codebase is set up to work well with agents: see
   [Harness engineering](https://openai.com/index/harness-engineering/).
2. Get a new personal token in Linear via Settings → Security & access → Personal API keys, and
   set it as the `LINEAR_API_KEY` environment variable.
3. Copy the repository root `WORKFLOW.md` to your repo.
4. Optionally copy the repository-owned workflow skills from `.agents/skills/` to your repo:
   `linear`, `commit`, `push`, `pull`, and `land`.
   These skills are adapted for OpenCode; `linear` uses configured Linear MCP tools or Symphony's
   `linear_graphql` app-server tool for raw Linear GraphQL operations.
5. Customize the copied `WORKFLOW.md` file for your project.
   - To get your project's slug, right-click the project and copy its URL. The slug is part of the
     URL.
   - When creating a workflow based on this repo, note that it depends on non-standard Linear
     issue statuses: "Rework", "Human Review", and "Merging". You can customize them in
     Team Settings → Workflow in Linear.
6. Follow the instructions below to install the required runtime dependencies and start the service.

## Prerequisites

We recommend using [mise](https://mise.jdx.dev/) to manage Elixir/Erlang versions.

```bash
mise install
mise exec -- elixir --version
```

## Run

```bash
git clone https://github.com/openai/symphony
cd symphony/elixir
mise trust
mise install
mise exec -- mix setup
mise exec -- mix build
mise exec -- ./bin/symphony ../../WORKFLOW.md
```

## Configuration

Pass a custom workflow file path to `./bin/symphony` when starting the service:

```bash
./bin/symphony /path/to/custom/WORKFLOW.md
```

If no path is passed, Symphony defaults to `./WORKFLOW.md`.

Optional flags:

- `--logs-root` tells Symphony to write logs under a different directory (default: `./log`)
- `--port` also starts the Phoenix observability service (default: disabled)

The `WORKFLOW.md` file uses YAML front matter for configuration, plus a Markdown body used as the
agent session prompt.

Minimal example:

```md
---
tracker:
  kind: linear
  project_slug: '...'
workspace:
  root: ~/code/workspaces
hooks:
  after_create: |
    git clone git@github.com:your-org/your-repo.git .
agent:
  max_concurrent_agents: 10
  max_turns: 20
---

You are working on a Linear issue {{ issue.identifier }}.

Title: {{ issue.title }} Body: {{ issue.description }}
```

Notes:

- If a value is missing, defaults are used.
- By default Symphony starts `opencode serve` through `opencode_client`. Set `OPENCODE_BASE_URL`
  to connect to an already-running OpenCode server instead.
- Set `OPENCODE_AUTH_USER` and `OPENCODE_AUTH_PASS` when the target OpenCode server requires
  HTTP basic auth.
- `tracker.required_labels` is optional. When set, an issue must have every
  configured label to dispatch or continue running. Label matching ignores
  case and surrounding whitespace. A blank configured label matches no issue.
- `tracker.reviewable_states` controls dependency unblocking for Todo issues blocked by Linear
  blockers. It defaults to `["Human Review"]`. Todo issues blocked by non-terminal,
  non-reviewable blockers stay claimed in the retry/backoff queue with dependency-wait metadata;
  when blockers become reviewable or terminal, Symphony dispatches the issue and uses an eligible
  blocker `branchName` as `issue.base_branch_name` for prompt templates and hooks.
- `opencode.model` can be set to a provider/model identifier such as `openai/gpt-5.5`; Symphony
  forwards it to the locally started `opencode serve` process. `opencode.turn_timeout_ms` controls
  the per-turn wait timeout.
- `agent.max_turns` caps how many back-to-back OpenCode turns Symphony will run in a single agent
  invocation when a turn completes normally but the issue is still in an active state. Default: `20`.
- If the Markdown body is blank, Symphony uses a default prompt template that includes the issue
  identifier, title, and body.
- Use `hooks.after_create` to bootstrap a fresh workspace. For a Git-backed repo, you can run
  `git clone ... .` there, along with any other setup commands you need.
- Workspace hooks receive `SYMPHONY_ISSUE_BRANCH_NAME` and `SYMPHONY_BASE_BRANCH_NAME` in their
  environment. The base branch is blank unless Symphony derived it from an eligible dependency
  blocker. Treat these tracker-derived values as untrusted input in hook scripts: quote them,
  validate branch syntax before use, and pass them after `--` where supported by the invoked tool.
- If a hook needs `mise exec` inside a freshly cloned workspace, trust the repo config and fetch
  the project dependencies in `hooks.after_create` before invoking `mise` later from other hooks.
- `tracker.api_key` reads from `LINEAR_API_KEY` when unset or when value is `$LINEAR_API_KEY`.
- For path values, `~` is expanded to the home directory.
- For env-backed path values, use `$VAR`. `workspace.root` resolves `$VAR` before path handling.

```yaml
tracker:
  api_key: $LINEAR_API_KEY
workspace:
  root: $SYMPHONY_WORKSPACE_ROOT
hooks:
  after_create: |
    git clone --depth 1 "$SOURCE_REPO_URL" .
```

- If `WORKFLOW.md` is missing or has invalid YAML at startup, Symphony does not boot.
- If a later reload fails, Symphony keeps running with the last known good workflow and logs the
  reload error until the file is fixed.
- `server.port` or CLI `--port` enables the optional Phoenix LiveView dashboard and JSON API at
  `/`, `/api/v1/state`, `/api/v1/<issue_identifier>`, and `/api/v1/refresh`.

## Web dashboard

The observability UI now runs on a minimal Phoenix stack:

- LiveView for the dashboard at `/`
- JSON API for operational debugging under `/api/v1/*`
- Bandit as the HTTP server
- Phoenix dependency static assets for the LiveView client bootstrap
- Tracker issue identifiers link to the tracker-provided URL when it uses `http` or `https`

## Project Layout

- `lib/`: application code and Mix tasks
- `test/`: ExUnit coverage for runtime behavior
- `../../WORKFLOW.md`: in-repo workflow contract used by local runs
- `../../.agents/`: repository-level agent skills and setup helpers

## Testing

Use Vite+ for the normal repository validation path, choosing the narrowest language or project
scope that covers your change. For this Symphony package, the usual scoped checks are:

```bash
vp run ex:check
vp run ex:test
```

Run tool-specific or expensive checks only when the change requires them. For example, Symphony's
package-local Dialyzer check is:

```bash
cd elixir/symphony
just dialyzer
```

Run the real external end-to-end test only when you want Symphony to create disposable Linear
resources and launch a real OpenCode session:

```bash
cd elixir/symphony
export LINEAR_API_KEY=...
just e2e
```

Optional environment variables:

- `SYMPHONY_LIVE_LINEAR_TEAM_KEY` defaults to `SYME2E`
- `SYMPHONY_LIVE_SSH_WORKER_HOSTS` uses those SSH hosts when set, as a comma-separated list

`just e2e` runs two live scenarios:

- one with a local worker
- one with SSH workers

If `SYMPHONY_LIVE_SSH_WORKER_HOSTS` is unset, the SSH scenario uses `docker compose` to start two
disposable SSH workers on `localhost:<port>`. The live test generates a temporary SSH keypair,
verifies that Symphony can talk to them over real SSH, then runs the same orchestration flow
against those worker addresses. This keeps the transport representative without depending on
long-lived external machines.

Set `SYMPHONY_LIVE_SSH_WORKER_HOSTS` if you want `just e2e` to target real SSH hosts instead.

The live test creates a temporary Linear project and issue, writes a temporary `WORKFLOW.md`, runs
a real agent turn, verifies the workspace side effect, requires the agent to comment on and close
the Linear issue, then marks the project completed so the run remains visible in Linear.

## FAQ

### Why Elixir?

Elixir is built on Erlang/BEAM/OTP, which is great for supervising long-running processes. It has an
active ecosystem of tools and libraries. It also supports hot code reloading without stopping
actively running subagents, which is very useful during development.

### What's the easiest way to set this up for my own codebase?

Launch your coding agent in your repo, give it the URL to the Symphony repo, and ask it to set
things up for you.

## License

This project is licensed under the [Apache License 2.0](LICENSE).
