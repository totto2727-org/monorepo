# MoonBit CLI Sources

> Document type: concrete MoonBit CLI implementation guidance.

## Source-of-truth priority

Apply CLI rules in this order:

1. The `totto2727/admiral` version pinned by the target module and its current public API.
2. The current Admiral-based implementations under `mbt/app/c-plugin`, `mbt/app/bw`, and `mbt/app/wt`.
3. Examples in this guide.

If this guide conflicts with the pinned Admiral API or those current implementations, follow Admiral and update this guide. Never restore direct `@argparse.Command` construction, manual parsing, or manual dispatch in `main.mbt` to preserve an older pattern.

For the current repository baseline, depend on `totto2727/admiral@0.4.0`. Keep the package name and version consistent in `moon.mod`, `moon.pkg`, and any generated compatibility manifest such as `package.nix`.
