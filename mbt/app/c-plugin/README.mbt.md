# c-plugin

Native MoonBit implementation of the `c-plugin` skill manager.

```bash
moon run ./src --target native -- init
moon run ./src --target native -- skill add --local ./
moon run ./src --target native -- skill sync
```

`moon build --target native` writes the native executable under the repository-root `_build/native/` tree. Move it or grant execute permissions only at the point where you need to run or package that artifact.
