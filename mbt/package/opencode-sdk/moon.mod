name = "totto2727/opencode-sdk"

version = "0.1.0"

readme = "README.md"

repository = "https://github.com/totto2727-org/monorepo"

license = "MIT"

keywords = [ "opencode", "sdk", "server", "process" ]

description = "Native MoonBit SDK for starting and managing an OpenCode server"

import {
  "DC-Z-lab/moonllm@0.1.0",
  "moonbitlang/async@0.20.1",
  "totto2727/admiral@0.4.0",
}

preferred_target = "native"

source = "src"

options(
  exclude: [ "package.json", "vite.config.ts" ],
)
