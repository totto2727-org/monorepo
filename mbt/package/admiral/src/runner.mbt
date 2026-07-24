///|
pub fn command(
  name~ : String,
  description? : String = "",
  options? : Array[&ToStoredOption] = [],
  positionals? : Array[&ToStoredPosition] = [],
  examples? : Array[String] = [],
  subcommands? : Array[CommandDef] = [],
  run? : (async (Context) -> Unit)? = None,
) -> CommandDef {
  let options = options.map(fn(option) {
    ToStoredOption::to_stored_option(option)
  })
  let positionals = positionals.map(fn(position) {
    ToStoredPosition::to_stored_position(position)
  })
  { name, description, options, positionals, examples, subcommands, run }
}

///|
pub fn cli(
  name~ : String,
  version? : String = "0.0.0",
  description? : String = "",
  options? : Array[&ToStoredOption] = [],
  commands? : Array[CommandDef] = [],
  load_config? : (() -> Map[String, Json] raise ConfigLoadFailure)? = None,
) -> CliApp {
  let root_options = options.map(fn(option) {
    ToStoredOption::to_stored_option(option)
  })
  { name, version, description, root_options, commands, load_config }
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
  {
    flags: m.flags,
    values: m.values,
    sources: m.sources,
    config,
    subcommand: sub,
  }
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
async fn execute_command(commands : Array[CommandDef], ctx : Context) -> Unit {
  match ctx.subcommand {
    Some((name, sub_ctx)) =>
      match find_command_def(commands, name) {
        Some(cmd) =>
          if cmd.subcommands.length() > 0 && sub_ctx.subcommand is Some(_) {
            execute_command(cmd.subcommands, sub_ctx)
          } else {
            match cmd.run {
              Some(run_fn) => run_fn(sub_ctx)
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
pub async fn CliApp::run(
  self : CliApp,
  argv? : Array[String]? = None,
  env? : Map[String, String] = @env.get_env_vars(),
) -> Unit {
  let config = match self.load_config {
    Some(load_config) => load_config()
    None => Map([])
  }
  let flags : Array[@argparse.FlagArg] = []
  let options : Array[@argparse.OptionArg] = []
  for opt in self.root_options {
    match opt.metadata.type_ {
      BoolOpt => flags.push(build_option_to_flag(opt))
      StringOpt | IntOpt | Int64Opt | UIntOpt | UInt64Opt | DoubleOpt =>
        options.push(build_option_to_option_arg(opt, config))
    }
  }
  let subcommands = self.commands.map(fn(c) {
    build_command_with_config(c, config)
  })
  let argparse_cmd = @argparse.Command(
    self.name,
    about=self.description,
    version=self.version,
    flags~,
    options~,
    subcommands~,
    arg_required_else_help=true,
  )
  let matches = match argv {
    Some(args) => argparse_cmd.parse(argv=args, env~)
    None => argparse_cmd.parse(env~)
  }
  let ctx = matches_to_context(matches, config)
  execute_command(self.commands, ctx)
}
