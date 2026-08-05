name = "totto2727/admiral"

version = "0.6.1"

readme = "README.md"

repository = "https://github.com/totto2727-org/monorepo"

license = "MIT"

keywords = [ "cli", "argparse", "moonbit" ]

description = "Async-first declarative CLI builder for MoonBit, inspired by gunshi"

import {
  "moonbitlang/async@0.20.3",
  "mizchi/tui@0.10.0",
  "totto2727/lens@0.4.0",
}

preferred_target = "native"

source = "src"

options(
  exclude: [ "package.json" ],
)
