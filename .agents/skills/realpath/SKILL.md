---
name: realpath
description: >-
  This skill should be used when performing path operations across platforms.
  Relevant when the user asks to calculate relative paths, convert to absolute
  paths, or resolve symbolic links.
  Common triggers: "relative path", "absolute path", "resolve symlink",
  "realpath", "grealpath", "path calculation".
---

# Cross-Platform Path Operations with realpath

## Platform Rule (CRITICAL)

| Platform  | Command     | Notes                                                                                                                               |
| --------- | ----------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| **macOS** | `grealpath` | Requires GNU coreutils (`brew install coreutils`). See [macos-cli-rules](../macos-cli-rules/SKILL.md) for full GNU coreutils usage. |
| **Linux** | `realpath`  | Available by default in GNU/Linux.                                                                                                  |

All examples below use `realpath`. **On macOS, replace every `realpath` with `grealpath`.**

## When to Use

**ALWAYS** use `realpath` for:

- Calculating relative paths between files/directories
- Converting relative paths to absolute paths
- Resolving symbolic links to absolute paths

**NEVER** manually calculate relative paths, use `cd`/`pwd` combinations, or use string manipulation for paths.

## Relative Path Calculation

Use `realpath --relative-to=<base>` to calculate relative paths:

```bash
# Calculate relative path from base directory to target
realpath --relative-to=/home/user /home/user/test
# Output: test

# Calculate relative path from current directory
realpath --relative-to=. ./subdir/file.txt
# Output: subdir/file.txt

# Calculate relative path between two specific paths
realpath --relative-to=/path/to/base /path/to/base/subdir/file.txt
# Output: subdir/file.txt
```

## Absolute Path Conversion

```bash
# Convert relative path to absolute path
realpath ./subdir/file.txt
# Output: /home/user/project/subdir/file.txt

# Resolve symbolic links to absolute paths
realpath symlink
# Output: /home/user/project/actual/path
```

## Key Notes

- The `--relative-to` option is a GNU extension — BSD `realpath` does not support it
- Paths are normalized (removes `.` and `..` components)
