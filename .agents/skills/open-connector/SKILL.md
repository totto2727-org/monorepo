---
name: open-connector
description: >-
  Consult the official oo skill and documentation for OpenConnector CLI usage.
---

# OpenConnector

Use the installed official `oo` skill when available.
Otherwise, consult the [official CLI reference](https://github.com/oomol-lab/oo-cli/blob/main/docs/commands.md) and [self-hosted connector guide](https://github.com/oomol-lab/oo-cli/blob/main/docs/self-hosted-connector.md).

## Login

Use the supplied environment variables to log in to this environment's connector:

```bash
oo connector login "$OPENCONNECTOR_BASE_URL" --token "$OPENCONNECTOR_TOKEN"
```
