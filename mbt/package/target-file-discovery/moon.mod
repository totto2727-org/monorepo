name = "package/target-file-discovery"

version = "0.0.0"

preferred_target = "native"

supported_targets = "native"

import {
  "moonbitlang/x@0.4.38",
  "moonbitlang/async@0.19.2",
}

readme = "README.md"

repository = "https://github.com/totto2727-org/monorepo"

license = "MIT"

keywords = [ "target-file-discovery", "filesystem", "gitignore" ]

description = "MoonBit port of @package/target-file-discovery"

options(
  source: "./src",
)
