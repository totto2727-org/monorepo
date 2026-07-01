name = "totto2727/bw"

version = "0.1.7"

preferred_target = "native"

supported_targets = "native"

import {
  "mizchi/admiral@0.1.0",
  "moonbitlang/x@0.4.38",
  "moonbitlang/async@0.19.2",
  "gmlewis/base64@0.16.10",
}

readme = "README.md"

repository = "https://github.com/totto2727-org/monorepo"

license = "MIT"

keywords = [ "cloudflare", "browser-rendering", "cli" ]

description = "Native MoonBit CLI for Cloudflare Browser Rendering API"

options(
  source: "./src",
)
