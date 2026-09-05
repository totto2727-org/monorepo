# MoonBit CLI Sources

> Document type: concrete MoonBit CLI implementation guidance.

## Source-of-truth priority

Apply CLI rules in this order:

1. The `totto2727/admiral` version pinned by the target module and its current public API.
2. The Admiral-based [standalone CLI implementation](https://github.com/totto2727-org/c-plugin/tree/5d6f66a83be6ed23d16d3c8535722970e028a003/src).
3. Examples in this guide.

If this guide conflicts with the pinned Admiral API or those current implementations, follow Admiral and update this guide. Never restore direct `@argparse.Command` construction, manual parsing, or manual dispatch in `main.mbt` to preserve an older pattern.

For the current repository baseline, depend on `totto2727/admiral@0.5.0`. Keep the package name and version consistent in `moon.mod`, `moon.pkg`, and any generated compatibility manifest such as `package.nix`.
