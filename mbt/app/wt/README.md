# wt

Native MoonBit implementation of the `wt` Git worktree manager.

```bash
moon run ./src --target native -- ls
moon run ./src --target native -- cleanup --dry-run
```

`moon build --target native` writes the native executable under the repository-root `_build/native/` tree. Move it or grant execute permissions only at the point where you need to run or package that artifact.
