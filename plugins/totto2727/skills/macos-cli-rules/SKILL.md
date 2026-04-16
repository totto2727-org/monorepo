---
name: macos-cli-rules
description: >-
  This skill must be loaded before executing any Bash tool command that involves
  coreutils on macOS (Darwin). On macOS, all coreutils commands (ls, find, sed,
  awk, grep, cat, cp, mv, rm, sort, head, tail, wc, cut, tr, xargs, stat,
  readlink, realpath, etc.) require the GNU 'g' prefix (gls, gfind, gsed, etc.).
  This skill applies whenever the platform is macOS/Darwin and shell commands
  are being constructed or executed. Always check this skill before writing
  Bash commands that use coreutils.
  DO NOT use this skill on Linux — standard coreutils commands work directly
  without any prefix on Linux/GNU systems.
---

# macOS CLI Rules

## Rule (CRITICAL)

**ALWAYS** use GNU coreutils commands with `g` prefix instead of Mac default BSD commands.

**NEVER** use Mac standard commands directly.

## Command Mapping

| GNU Command (Use) | Mac BSD Command (Prohibited) | Description                                          |
| ----------------- | ---------------------------- | ---------------------------------------------------- |
| `gls`             | `ls`                         | List directory contents                              |
| `gfind`           | `find`                       | Find files                                           |
| `gsed`            | `sed`                        | Stream editor                                        |
| `gawk`            | `awk`                        | Pattern scanning and processing                      |
| `ggrep`           | `grep`                       | Search patterns                                      |
| `gcat`            | `cat`                        | Concatenate files                                    |
| `gcp`             | `cp`                         | Copy files                                           |
| `gmv`             | `mv`                         | Move files                                           |
| `grm`             | `rm`                         | Remove files                                         |
| `gmkdir`          | `mkdir`                      | Create directories                                   |
| `gchmod`          | `chmod`                      | Change file permissions                              |
| `gchown`          | `chown`                      | Change file ownership                                |
| `gdate`           | `date`                       | Display/set date                                     |
| `gtouch`          | `touch`                      | Change file timestamps                               |
| `ghead`           | `head`                       | Display first lines                                  |
| `gtail`           | `tail`                       | Display last lines                                   |
| `gsort`           | `sort`                       | Sort lines                                           |
| `guniq`           | `uniq`                       | Remove duplicate lines                               |
| `gwc`             | `wc`                         | Word count                                           |
| `gcut`            | `cut`                        | Cut fields                                           |
| `gtr`             | `tr`                         | Translate characters                                 |
| `gxargs`          | `xargs`                      | Build and execute commands                           |
| `gstat`           | `stat`                       | Display file status                                  |
| `greadlink`       | `readlink`                   | Read symbolic links                                  |
| `gln`             | `ln`                         | Create links                                         |
| `gshuf`           | `shuf`                       | Shuffle lines                                        |
| `gsplit`          | `split`                      | Split files                                          |
| `gbase64`         | `base64`                     | Base64 encode/decode                                 |
| `gmd5sum`         | `md5`                        | MD5 checksum                                         |
| `gsha256sum`      | `shasum`                     | SHA256 checksum                                      |
| `grealpath`       | `realpath`                   | Resolve paths (see [realpath](../realpath/SKILL.md)) |

## Examples

### Good: Using GNU Commands

```bash
# List files
gls -la

# Find files
gfind . -name "*.ts" -type f

# Find and process
gfind . -name "*.log" -mtime +30 -delete

# Text processing
gsed -i 's/old/new/g' file.txt
ggrep -E "pattern1|pattern2" file.txt
gawk '{print $1, $3}' file.txt

# File operations
gcp -r source/ dest/
gmv file.txt newdir/
grm -rf directory/
```

### Bad: Using Mac BSD Commands (PROHIBITED)

```bash
ls -la
find . -name "*.ts"
sed -i '' 's/old/new/g' file.txt
grep -r "pattern" .
cp source.txt dest.txt
```

## Path Operations

For path calculations (relative paths, absolute path conversion, symlink resolution), see the dedicated [realpath](../realpath/SKILL.md) skill.

## Platform Note

- **macOS**: Use this skill — all coreutils commands require the `g` prefix.
- **Linux**: Use standard coreutils commands directly (no prefix needed). This skill does not apply.

## Installation Note

GNU coreutils can be installed via Homebrew:

```bash
brew install coreutils
```

After installation, commands are available with `g` prefix.

## Rationale

- GNU coreutils provide consistent behavior across platforms
- Better compatibility with Linux systems
- More features and options than BSD versions
- Consistent behavior in scripts across different environments
