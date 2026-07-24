///|
fn has_short(opt : StoredOption) -> Bool {
  opt.metadata.short != no_short
}

///|
fn build_option_to_flag(opt : StoredOption) -> @argparse.FlagArg {
  let metadata = opt.metadata
  let env = metadata.env.map(fn(value) { value[:] })
  if has_short(opt) {
    @argparse.FlagArg(
      opt.name,
      short=metadata.short,
      about=metadata.description,
      env?,
    )
  } else {
    @argparse.FlagArg(opt.name, about=metadata.description, env?)
  }
}

///|
fn build_option_to_option_arg(
  opt : StoredOption,
  config : Map[String, Json],
) -> @argparse.OptionArg {
  let metadata = opt.metadata
  let env = metadata.env.map(fn(value) { value[:] })
  let required = metadata.required && !config_contains_argument(config, opt)
  let action = if metadata.multiple {
    @argparse.OptionAction::Append
  } else {
    @argparse.OptionAction::Set
  }
  match (has_short(opt), metadata.default_value, required) {
    (true, Some(dv), _) =>
      @argparse.OptionArg(
        opt.name,
        short=metadata.short,
        about=metadata.description,
        action~,
        env?,
        default_values=[dv],
      )
    (true, None, true) =>
      @argparse.OptionArg(
        opt.name,
        short=metadata.short,
        about=metadata.description,
        action~,
        env?,
        required=true,
      )
    (true, None, false) =>
      @argparse.OptionArg(
        opt.name,
        short=metadata.short,
        about=metadata.description,
        action~,
        env?,
      )
    (false, Some(dv), _) =>
      @argparse.OptionArg(opt.name, about=metadata.description, action~, env?, default_values=[
        dv,
      ])
    (false, None, true) =>
      @argparse.OptionArg(
        opt.name,
        about=metadata.description,
        action~,
        env?,
        required=true,
      )
    (false, None, false) =>
      @argparse.OptionArg(opt.name, about=metadata.description, action~, env?)
  }
}

///|
fn build_position(
  position : StoredPosition,
  config : Map[String, Json],
) -> @argparse.PositionArg {
  let metadata = position.metadata
  let required = metadata.required &&
    !config_contains_argument(config, position)
  let num_args = match (required, metadata.multiple) {
    (true, false) => @argparse.ValueRange::single()
    (false, false) => @argparse.ValueRange(lower=0, upper=1)
    (true, true) => @argparse.ValueRange(lower=1)
    (false, true) => @argparse.ValueRange(lower=0)
  }
  @argparse.PositionArg(position.name, about=metadata.description, num_args~)
}

///|
fn[T, Metadata] config_contains_argument(
  config : Map[String, Json],
  argument : ArgDef[T, Metadata],
) -> Bool {
  match argument.config {
    Some(key) => config.contains(key)
    None => false
  }
}

///|
fn fallback_to_help_when_no_match(cmd : CommandDef) -> Bool {
  cmd.run is None
}

///|
fn build_command_with_config(
  cmd : CommandDef,
  config : Map[String, Json],
) -> @argparse.Command {
  let flags : Array[@argparse.FlagArg] = []
  let options : Array[@argparse.OptionArg] = []
  for opt in cmd.options {
    match opt.metadata.type_ {
      BoolOpt => flags.push(build_option_to_flag(opt))
      StringOpt | IntOpt | Int64Opt | UIntOpt | UInt64Opt | DoubleOpt =>
        options.push(build_option_to_option_arg(opt, config))
    }
  }
  let positionals = cmd.positionals.map(fn(position) {
    build_position(position, config)
  })
  let subcommands = cmd.subcommands.map(fn(sub) {
    build_command_with_config(sub, config)
  })
  @argparse.Command(
    cmd.name,
    about=cmd.description,
    flags~,
    options~,
    positionals~,
    subcommands~,
    arg_required_else_help=fallback_to_help_when_no_match(cmd),
  )
}

///|
pub fn build_command(cmd : CommandDef) -> @argparse.Command {
  build_command_with_config(cmd, Map([]))
}
