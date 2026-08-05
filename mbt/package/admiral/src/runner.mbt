///|
pub fn command(
  name~ : String,
  description? : String = "",
  options? : Array[&ToStoredOption] = [],
  positionals? : Array[&ToStoredPosition] = [],
  examples? : Array[String] = [],
  subcommands? : Array[CommandDef] = [],
  interactive? : (async (InteractiveContext) -> Unit)? = None,
  run? : (async (Context) -> Unit)? = None,
) -> CommandDef {
  let options = options.map(fn(option) {
    ToStoredOption::to_stored_option(option)
  })
  let positionals = positionals.map(fn(position) {
    ToStoredPosition::to_stored_position(position)
  })
  {
    name,
    description,
    options,
    positionals,
    examples,
    subcommands,
    interactive,
    run,
  }
}

///|
pub fn cli(
  name~ : String,
  version? : String = "0.0.0",
  description? : String = "",
  options? : Array[&ToStoredOption] = [],
  positionals? : Array[&ToStoredPosition] = [],
  commands? : Array[CommandDef] = [],
  interactive? : (async (InteractiveContext) -> Unit)? = None,
  run? : (async (Context) -> Unit)? = None,
  load_config? : (() -> Map[String, Json] raise ConfigLoadFailure)? = None,
) -> CliApp {
  let root_options = options.map(fn(option) {
    ToStoredOption::to_stored_option(option)
  })
  let root_positionals = positionals.map(fn(position) {
    ToStoredPosition::to_stored_position(position)
  })
  {
    name,
    version,
    description,
    root_options,
    root_positionals,
    commands,
    interactive,
    run,
    load_config,
  }
}

///|
fn matches_to_context(
  m : @argparse.Matches,
  config : Map[String, Json],
) -> Context {
  let sub = match m.subcommand {
    Some((name, sub_matches)) =>
      Some((name, matches_to_context(sub_matches, config)))
    None => None
  }
  Context(
    flags=m.flags,
    values=m.values,
    sources=m.sources,
    config~,
    subcommand=sub,
  )
}

///|
fn find_command_def(commands : Array[CommandDef], name : String) -> CommandDef? {
  for cmd in commands {
    if cmd.name == name {
      return Some(cmd)
    }
  }
  None
}

///|
fn build_root_command(
  app : CliApp,
  config : Map[String, Json],
  interactive_environment? : Bool = false,
) -> @argparse.Command {
  let interactive = interactive_environment && app.interactive is Some(_)
  let flags : Array[@argparse.FlagArg] = []
  let options : Array[@argparse.OptionArg] = []
  for opt in app.root_options {
    match opt.metadata.type_ {
      BoolOpt => flags.push(build_option_to_flag(opt, global=true))
      StringOpt | IntOpt | Int64Opt | UIntOpt | UInt64Opt | DoubleOpt =>
        options.push(
          build_option_to_option_arg(opt, config, interactive~, global=true),
        )
    }
  }
  let subcommands = app.commands.map(fn(c) {
    build_command_with_config(c, config, interactive_environment~)
  })
  let positionals = app.root_positionals.map(fn(position) {
    build_position(position, config, interactive~)
  })
  @argparse.Command(
    app.name,
    about=app.description,
    version=app.version,
    flags~,
    options~,
    positionals~,
    subcommands~,
    arg_required_else_help=app.run is None,
  )
}

///|
fn print_help(command : @argparse.Command) -> Unit {
  let help = command.render_help()
  match help.strip_suffix("\n") {
    Some(text) => println(text)
    None => println(help)
  }
}

///|
fn has_interactive_arguments(
  options : Array[StoredOption],
  positionals : Array[StoredPosition],
) -> Bool {
  for option in options {
    if option.metadata.interactive {
      return true
    }
  }
  for position in positionals {
    if position.metadata.interactive {
      return true
    }
  }
  false
}

///|
async fn apply_interactive_input(
  context : Context,
  options : Array[StoredOption],
  positionals : Array[StoredPosition],
  interactive : (async (InteractiveContext) -> Unit)?,
  interactive_environment : Bool,
) -> Context {
  if !interactive_environment ||
    !has_interactive_arguments(options, positionals) {
    return context
  }
  match interactive {
    Some(run_interactive) => {
      let input = InteractiveContext::InteractiveContext(context)
      run_interactive(input)
      input.to_context()
    }
    None => context
  }
}

///|
async fn execute_command(
  commands : Array[CommandDef],
  ctx : Context,
  interactive_environment : Bool,
) -> Unit {
  match ctx.subcommand {
    Some((name, sub_ctx)) =>
      match find_command_def(commands, name) {
        Some(cmd) =>
          if cmd.subcommands.length() > 0 && sub_ctx.subcommand is Some(_) {
            execute_command(cmd.subcommands, sub_ctx, interactive_environment)
          } else {
            match cmd.run {
              Some(run_fn) => {
                let command_context = apply_interactive_input(
                  sub_ctx,
                  cmd.options,
                  cmd.positionals,
                  cmd.interactive,
                  interactive_environment,
                )
                run_fn(command_context)
              }
              None => {
                let subs = cmd.subcommands.map(fn(c) { c.name }).join(", ")
                fail(
                  "missing subcommand for '" + name + "'. Available: " + subs,
                )
              }
            }
          }
        None => fail("unknown command: " + name)
      }
    None => fail("no command specified. Use --help for usage.")
  }
}

///|
async fn CliApp::run_with_interactive_environment(
  self : CliApp,
  interactive_environment : Bool,
  argv? : Array[String]? = None,
  env? : Map[String, String] = @env.get_env_vars(),
) -> Unit {
  let config = match self.load_config {
    Some(load_config) => load_config()
    None => Map([])
  }
  let argparse_cmd = build_root_command(self, config, interactive_environment~)
  let matches = match argv {
    Some(args) => argparse_cmd.parse(argv=args, env~)
    None => argparse_cmd.parse(env~)
  }
  let ctx = matches_to_context(matches, config)
  let root_context = apply_interactive_input(
    ctx,
    self.root_options,
    self.root_positionals,
    self.interactive,
    interactive_environment,
  )
  match (root_context.subcommand, self.run) {
    (Some(_), _) =>
      execute_command(self.commands, root_context, interactive_environment)
    (None, Some(run)) => run(root_context)
    (None, None) => print_help(argparse_cmd)
  }
}

///|
/// Parses inputs and runs the selected callback, invoking interactive input only
/// when at least one selected definition opts in and an input TTY is available.
pub async fn CliApp::run(
  self : CliApp,
  argv? : Array[String]? = None,
  env? : Map[String, String] = @env.get_env_vars(),
) -> Unit {
  self.run_with_interactive_environment(@tui_io.is_tty(), argv~, env~)
}
