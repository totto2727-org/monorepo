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
