---
name: zmx
description: >-
  This skill should be used when managing persistent terminal sessions with zmx.
  Relevant when the user asks to run background processes, start dev servers,
  manage long-running tasks, or work with terminal session multiplexing.
  Common triggers: "run in background", "start dev server", "attach session",
  "check session output", "list sessions", "kill session", "zmx".
  Alternative to tmux/screen for session persistence.
---

# zmx - Session Persistence for Terminal Processes

A terminal session manager for running and managing persistent processes.

## Session Management

| Command                          | Purpose                                         |
| -------------------------------- | ----------------------------------------------- |
| `zmx attach <name> [command...]` | Create a session and attach to it (interactive) |
| `zmx run <name> [command...]`    | Create a session without attaching (background) |
| `zmx list [--short]`             | List all active sessions                        |
| `zmx kill <name>`                | Terminate a session                             |
| `zmx detach`                     | Detach all clients from the current session     |

## History Retrieval

| Command                     | Output Format                     |
| --------------------------- | --------------------------------- |
| `zmx history <name>`        | Plain text (default)              |
| `zmx history <name> --vt`   | With VT escape sequences (colors) |
| `zmx history <name> --html` | HTML formatted output             |

## Workflow: `attach` vs `run`

- **`zmx run`** — Use for background/non-interactive processes (dev servers, build watchers, log tailers). The process runs detached and you can check output later with `zmx history`.
- **`zmx attach`** — Use for interactive processes where you need to provide input (REPLs, interactive CLIs). Attaches your terminal directly to the session.

## Common Patterns

### Start a dev server in the background

```bash
zmx run dev-server vp dev --port 3000
```

### Check dev server output

```bash
zmx history dev-server
```

### Run a long build and monitor later

```bash
zmx run build vp build
# ... do other work ...
zmx history build
```

### Interactive REPL session

```bash
zmx attach db-repl psql -d mydb
```

### Clean up finished sessions

```bash
zmx list
zmx kill build
```

### Run multiple services

```bash
zmx run api vp dev --port 3000
zmx run worker deno run --allow-all worker.ts
zmx list
```
