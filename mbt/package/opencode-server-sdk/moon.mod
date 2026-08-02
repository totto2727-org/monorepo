name = "totto2727/opencode-server-sdk"

version = "0.2.0"

readme = "README.md"

repository = "https://github.com/totto2727-org/monorepo"

license = "MIT"

keywords = [ "opencode", "sdk", "server", "process" ]

description = "Native MoonBit SDK for starting and managing an OpenCode server"

import {
  "moonbitlang/async@0.20.1",
  "totto2727/lens@0.4.0",
}

preferred_target = "native"

source = "src"

options(
  exclude: [ "package.json" ],
)
