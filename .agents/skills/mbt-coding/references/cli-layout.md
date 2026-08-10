# MoonBit CLI Layout

> Document type: concrete MoonBit CLI implementation guidance.

## File organization

Split CLI implementations by command:

```text
src/
  main.mbt                  # Admiral app construction + app.run() only
  auth.mbt                  # environment variable names only
  http_client.mbt           # HTTP send / response status boundary
  output.mbt                # output writing helpers
  command_content.mbt       # content command
  command_markdown.mbt      # markdown command
  command_screenshot.mbt    # screenshot command
  ...
```

`main.mbt` should only construct the Admiral app and call `app.run()`. Admiral owns parsing and dispatch. Command-specific validation, options conversion, body construction, and execution belong in the command file.

```moonbit
///|
async fn main {
  let app = @admiral.cli(
    name="myapp",
    description="My CLI application",
    commands=[
      status_command_def(run_status),
      @admiral.command(
        name="config",
        description="Manage configuration",
        subcommands=[
          config_show_command_def(run_config_show),
          config_set_command_def(run_config_set),
        ],
      ),
    ],
  )
  app.run()
}
```

Do not add a task group, background spawn, explicit `@env.args()` help rewrite, `help_path`, manual parse function, or dispatch match around `app.run()`. Admiral displays the relevant help when no runnable command or required subcommand is supplied. Unknown commands, invalid options, and errors from command callbacks remain errors.
