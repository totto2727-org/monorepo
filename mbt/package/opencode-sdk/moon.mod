name = "totto2727/opencode-sdk"

version = "0.2.1"

preferred_target = "native"

supported_targets = "native"

import {
  "moonbitlang/x@0.4.38",
  "moonbitlang/async@0.20.1",
  "totto2727/agent-cli-sdk@0.2.0",
  "totto2727/copy@0.2.0",
  "totto2727/lens@0.3.0",
}

readme = "README.md"

repository = "https://github.com/totto2727-org/monorepo"

license = "MIT"

keywords = [ "opencode", "sdk", "cli", "moonbit" ]

description = "MoonBit SDK for running OpenCode through its CLI"

source = "./src"

options(
  exclude: [ "package.json" ],
)
