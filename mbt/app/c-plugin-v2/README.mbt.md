# c-plugin v2

Native MoonBit bootstrap for the next c-plugin implementation.

The executable keeps the public command name `c-plugin` while the v1 and v2 packages coexist under separate module and Nix identities.

```bash
moon run ./mbt/app/c-plugin-v2/src --target native -- --help
moon run ./mbt/app/c-plugin-v2/src --target native -- --version
```
