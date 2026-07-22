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
  load_config? : (() -> Map[String, String] raise ConfigLoadFailure)? = None,
) -> CliApp {
  let root_options = options.map(fn(option) {
    ToStoredOption::to_stored_option(option)
  })
  { name, version, description, root_options, commands, load_config }
}

///|
fn matches_to_context(m : @argparse.Matches) -> Context {
  let sub = match m.subcommand {
    Some((name, sub_matches)) => Some((name, matches_to_context(sub_matches)))
    None => None
  }
  { flags: m.flags, values: m.values, subcommand: sub }
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
  let flags : Array[@argparse.FlagArg] = []
  let options : Array[@argparse.OptionArg] = []
  for opt in self.root_options {
    match opt.metadata.type_ {
      BoolOpt => flags.push(build_option_to_flag(opt, global=true))
      StringOpt | IntOpt | Int64Opt | UIntOpt | UInt64Opt | DoubleOpt =>
        options.push(build_option_to_option_arg(opt, global=true))
    }
  }
  let subcommands = self.commands.map(fn(c) { build_command(c) })
  let argparse_cmd = @argparse.Command(
    self.name,
    about=self.description,
    version=self.version,
    flags~,
    options~,
    subcommands~,
    arg_required_else_help=true,
  )
  let effective_env = match self.load_config {
    Some(load_config) => load_config().merge(env)
    None => env
  }
  let matches = match argv {
    Some(args) => argparse_cmd.parse(argv=args, env=effective_env)
    None => argparse_cmd.parse(env=effective_env)
  }
  let ctx = matches_to_context(matches)
  execute_command(self.commands, ctx)
}
