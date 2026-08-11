///|
test "CliApp app - exposes init and skill add and sync commands" {
  let paths = RuntimePaths::RuntimePaths(
    "/tmp/c-plugin-v2-main-home", "/tmp/c-plugin-v2-main-cwd", "/tmp/c-plugin-v2-main-cache",
  )
  let runtime = runtime_for_init(paths)
  let cli = app(runtime)
  inspect(cli.name, content="c-plugin")
  inspect(cli.version, content="0.1.0")
  inspect(cli.commands.length(), content="2")
  inspect(cli.commands[0].name, content="init")
  inspect(cli.commands[1].name, content="skill")
  inspect(cli.commands[1].subcommands.length(), content="2")
  inspect(cli.commands[1].subcommands[0].name, content="add")
  inspect(cli.commands[1].subcommands[1].name, content="sync")
}
