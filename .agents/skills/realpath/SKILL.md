---
name: realpath
description: >-
  Calculate relative or canonical filesystem paths with realpath. Use for shell path calculations and symlink resolution.
---

# Filesystem Path Calculations

Use a path-aware tool rather than splitting strings on separators.
In application code, prefer the language's path API instead of spawning a shell command.

## Choose the required semantics

- Use canonicalization when the result must resolve filesystem symlinks.
- Use a lexical path operation when the result must preserve symlinks or need not refer to an existing file.
- Keep filesystem paths separate from URLs.

The examples below use GNU `realpath`.
On macOS, GNU coreutils commonly provides it as `grealpath`; check the available implementation before relying on GNU options.
This is not a requirement to replace unrelated shell utilities or install packages for every path operation.

## Relative path

GNU `--relative-to` computes a path from a base directory to the target:

```bash
realpath --relative-to=/home/user /home/user/project/file.txt
# project/file.txt
```

Quote variable paths, for example `realpath --relative-to="$base" -- "$target"`.
Use `grealpath` for this example when that is the installed GNU executable.

## Canonical absolute path

```bash
realpath -- ./subdir/file.txt
realpath -- ./symlink
```

Canonicalization resolves symlinks and normalizes `.` and `..`.
GNU `-e` requires every path component to exist; `-m` allows missing components.
Choose deliberately when existence affects the task, and check command failures instead of treating empty output as a path.
