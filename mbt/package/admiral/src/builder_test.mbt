///|
test "build_command converts simple command" {
  let cmd = command(
    name="greet",
    description="Greet someone",
    options=[
      string("name", short='n', description="Name to greet", required=true),
      bool("verbose", short='v', description="Verbose output"),
      int("count", short='c', description="Repeat count", default=Some(1)),
      int64("offset", description="Signed 64-bit offset"),
      uint("retries", description="Unsigned count"),
      uint64("limit", description="Unsigned 64-bit limit"),
      double("ratio", description="Floating-point ratio"),
    ],
    run=Some(fn(_ctx) { () }),
  )
  let argparse_cmd = build_command(cmd)
  let help = argparse_cmd.render_help()
  inspect(help.contains("greet"), content="true")
  inspect(help.contains("--name"), content="true")
  inspect(help.contains("--verbose"), content="true")
  inspect(help.contains("--count"), content="true")
  inspect(help.contains("--offset"), content="true")
  inspect(help.contains("--retries"), content="true")
  inspect(help.contains("--limit"), content="true")
  inspect(help.contains("--ratio"), content="true")
}

///|
test "build_command converts nested subcommands" {
  let sub = command(
    name="serve",
    description="Start server",
    options=[int("port", short='p', description="Port")],
    run=Some(fn(_ctx) { () }),
  )
  let root = command(name="app", description="My app", subcommands=[sub])
  let argparse_cmd = build_command(root)
  let help = argparse_cmd.render_help()
  inspect(help.contains("serve"), content="true")
}

///|
test "build_command exposes configured option environment variables in help" {
  let cmd = command(
    name="greet",
    description="Greet someone",
    options=[
      string("name", description="Name to greet", env="APP_NAME"),
      string("output", description="Output path"),
    ],
    run=Some(fn(_ctx) { () }),
  )
  let help = build_command(cmd).render_help()
  inspect(help.contains("APP_NAME"), content="true")
  inspect(help.contains("Output path [env:"), content="false")
}
