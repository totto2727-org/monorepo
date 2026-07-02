name = "totto2727/c-plugin"

version = "0.1.0"

preferred_target = "native"

supported_targets = "native"

import {
  "mizchi/admiral@0.1.0",
  "moonbitlang/async@0.19.2",
  "totto2727/c-plugin-support@0.1.0",
}

readme = "README.md"

repository = "https://github.com/totto2727-org/monorepo"

license = "MIT"

keywords = [ "claude", "cursor", "codex", "plugin", "cli" ]

description = "Native MoonBit Claude/Cursor/Codex plugin skill manager"

options(
  source: "./src",
)
