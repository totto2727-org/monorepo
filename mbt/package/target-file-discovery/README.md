# @package/target-file-discovery

MoonBit port of the original `@package/target-file-discovery` local package.

It provides reusable helpers to:

- find a target file directly under a home-level directory
- find the nearest target file in ancestors bounded by a top directory
- collect target files recursively while using `.gitignore` rules only to decide whether directories should be traversed

`moon build --target native` writes build artifacts under the repository-root `_build/native/` tree.
