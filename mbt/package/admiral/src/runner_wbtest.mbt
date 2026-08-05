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

///|
async test "CliApp run_with_interactive_environment 1 - passes resolved initial values and selected overrides" {
  let project = position_string("project", interactive=true)
  let query = string("query", interactive=true)
  let profile = string(
    "profile",
    env="ADMIRAL_INTERACTIVE_PROFILE",
    interactive=true,
  )
  let limit = int("limit", default=Some(10), interactive=true)
  let initial_values = Ref("")
  let selected_project = Ref("")
  let app = cli(name="demo", commands=[
    command(
      name="select",
      options=[query, profile, limit],
      positionals=[project],
      interactive=Some(input => {
        let initial = input.to_context()
        initial_values.val = [
          initial.get_string(project).unwrap_or(""),
          initial.get_string(query).unwrap_or(""),
          initial.get_string(profile).unwrap_or(""),
          initial.get_int(limit).unwrap_or(0).to_string(),
        ].join(":")
        input.set_string(project, "selected-project")
      }),
      run=Some(ctx => {
        selected_project.val = ctx.get_string(project).unwrap_or("")
      }),
    ),
  ])
  app.run_with_interactive_environment(
    true,
    argv=Some(["select", "argv-project", "--query", "argv-query"]),
    env={ "ADMIRAL_INTERACTIVE_PROFILE": "env-profile" },
  )
  inspect(initial_values.val, content="argv-project:argv-query:env-profile:10")
  inspect(selected_project.val, content="selected-project")
}

///|
async test "CliApp run_with_interactive_environment 2 - lets interactive input satisfy a required value" {
  let project = position_string("project", required=true, interactive=true)
  let selected_project = Ref("")
  let app = cli(name="demo", commands=[
    command(
      name="select",
      positionals=[project],
      interactive=Some(input => input.set_string(project, "chosen")),
      run=Some(ctx => {
        selected_project.val = ctx.get_string_required(project) catch {
          _ => "missing"
        }
      }),
    ),
  ])
  app.run_with_interactive_environment(true, argv=Some(["select"]), env=Map([]))
  inspect(selected_project.val, content="chosen")
}

///|
async test "CliApp run_with_interactive_environment 3 - skips interactive callback outside a TTY" {
  let project = position_string("project", interactive=true)
  let callback_called = Ref(false)
  let selected_project = Ref("")
  let app = cli(name="demo", commands=[
    command(
      name="select",
      positionals=[project],
      interactive=Some(input => {
        callback_called.val = true
        input.set_string(project, "selected")
      }),
      run=Some(ctx => {
        selected_project.val = ctx.get_string(project).unwrap_or("")
      }),
    ),
  ])
  app.run_with_interactive_environment(
    false,
    argv=Some(["select", "argv-project"]),
    env=Map([]),
  )
  inspect(callback_called.val, content="false")
  inspect(selected_project.val, content="argv-project")
}

///|
async test "CliApp run_with_interactive_environment 4 - requires an opted-in definition" {
  let project = position_string("project")
  let callback_called = Ref(false)
  let app = cli(name="demo", commands=[
    command(
      name="select",
      positionals=[project],
      interactive=Some(_ => callback_called.val = true),
      run=Some(_ => ()),
    ),
  ])
  app.run_with_interactive_environment(
    true,
    argv=Some(["select", "argv-project"]),
    env=Map([]),
  )
  inspect(callback_called.val, content="false")
}

///|
async test "CliApp run_with_interactive_environment 5 - propagates root interactive values to a subcommand" {
  let profile = string("profile", interactive=true)
  let selected_profile = Ref("")
  let app = cli(
    name="demo",
    options=[profile],
    interactive=Some(input => input.set_string(profile, "interactive-profile")),
    commands=[
      command(
        name="show",
        run=Some(ctx => {
          selected_profile.val = ctx.get_string(profile).unwrap_or("")
        }),
      ),
    ],
  )
  app.run_with_interactive_environment(true, argv=Some(["show"]), env=Map([]))
  inspect(selected_profile.val, content="interactive-profile")
}
