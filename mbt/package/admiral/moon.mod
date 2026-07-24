name = "totto2727/admiral"

version = "0.5.0"

readme = "README.md"

repository = "https://github.com/totto2727-org/monorepo"

license = "MIT"

keywords = [ "cli", "argparse", "moonbit" ]

description = "Async-first declarative CLI builder for MoonBit, inspired by gunshi"

import {
  "moonbitlang/async@0.20.1",
}

preferred_target = "native"

source = "src"

options(
  exclude: [ "package.json", "vite.config.ts" ],
)
