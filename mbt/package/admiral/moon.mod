name = "totto2727/admiral"

version = "0.3.0"

readme = "README.md"

repository = "https://github.com/totto2727-org/monorepo"

license = "MIT"

keywords = [ "cli", "argparse", "moonbit" ]

description = "Async-first declarative CLI builder for MoonBit, inspired by gunshi"

import {
  "moonbitlang/async@0.19.2",
}

preferred_target = "native"

source = "src"

options(exclude: ["package.json", "vite.config.ts"])
