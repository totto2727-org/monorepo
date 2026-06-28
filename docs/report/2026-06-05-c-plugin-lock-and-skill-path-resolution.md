# c-plugin lock and skill path resolution report

## Current behavior found

`c-plugin` treated `.agents/` as both the managed runtime directory and the lock-file directory. As a result, `c-plugin skill sync -g` read and wrote `~/.agents/c-plugin-lock.json`, and recursive sync discovered lock files inside each `.agents/` directory.

Additional `skillDirs` were expanded directly from the stored value. Absolute paths and `~/...` paths worked, but relative entries depended on downstream filesystem interpretation and could effectively resolve from the current process directory.

## New rule implemented

The lock file is always located next to the target `.agents/` directory:

```text
<root>/.agents/
<root>/c-plugin-lock.json
```

This applies uniformly to default, `--global`, and `--recursive` command paths. Global mode therefore uses `~/.agents/` as the agents directory and `~/c-plugin-lock.json` as the lock file.

Default mode searches upward from the current directory and selects the nearest ancestor lock file. Recursive mode first performs that same nearest-ancestor lock search, then scans downward from that lock-file directory and maps each descendant `c-plugin-lock.json` to its corresponding `.agents/` runtime directory.

`skillDirs` now resolve relative to the directory that contains the lock file. Absolute paths stay absolute, and `~` / `~/...` paths still expand to the user home directory.

## Affected implementation points

- `src/lib/paths.ts`: lock-file path calculation and nearest-agent discovery are lock-file based.
- `src/service/discover.ts`: recursive discovery anchors at the nearest ancestor lock file, then scans descendant lock files.
- `src/service/symlink.ts`: additional skill target directories resolve from the lock-file directory.
- `src/cli/skill/target/add.ts` and `target/remove.ts`: duplicate detection and targeted cleanup use the same skill directory resolution rule.

## Reusable target-file discovery package

The generic discovery behavior was extracted to `js/package/target-file-discovery` for reuse by other CLIs. It exposes focused Effect-based helpers for home-level file resolution, parent/upward file discovery, and recursive descendant discovery. It intentionally does not expose a combined mode resolver; callers compose only the primitive they need for each CLI path.

Recursive descendant discovery honors `.gitignore` files with inherited parent rules. The ancestor lookup used before recursive traversal does not read `.gitignore`; ignore filtering starts when walking downward from the nearest ancestor target file directory.
