name = "totto2727/agent-cli-sdk"

version = "0.1.0"

preferred_target = "native"

supported_targets = "native"

import {
  "moonbitlang/async@0.20.1",
}

readme = "README.md"

repository = "https://github.com/totto2727-org/monorepo"

license = "MIT"

keywords = [ "agent", "cli", "jsonl", "sdk", "moonbit" ]

description = "Shared MoonBit process foundation for JSONL agent CLIs"

source = "./src"

options(
  exclude: [ "package.json" ],
)
