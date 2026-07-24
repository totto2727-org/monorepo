///|
test "command without run falls back to help when no match exists" {
  let command_without_run = command(name="group")
  inspect(fallback_to_help_when_no_match(command_without_run), content="true")
}

///|
test "runnable command preserves normal execution" {
  let runnable = command(name="run", run=Some(fn(_ctx) { () }))
  inspect(fallback_to_help_when_no_match(runnable), content="false")
}

///|
test "root without run renders generated help after parsing root options" {
  let verbose = bool("verbose", description="Show verbose output")
  let serve = command(name="serve", description="Start the server")
  let app = cli(
    name="demo",
    description="Demo application",
    options=[verbose],
    commands=[serve],
  )
  inspect(
    build_root_command(app, Map([])).render_help(),
    content=(
      #|Usage: demo [options] [command]
      #|
      #|Demo application
      #|
      #|Commands:
      #|  serve  Start the server
      #|  help   Print help for the subcommand(s).
      #|
      #|Options:
      #|  -h, --help     Show help information.
      #|  -V, --version  Show version information.
      #|  --verbose      Show verbose output
      #|
    ),
  )
}
