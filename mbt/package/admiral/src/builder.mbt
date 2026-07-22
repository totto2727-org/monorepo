///|
fn has_short(opt : StoredOption) -> Bool {
  opt.metadata.short != no_short
}

///|
fn build_option_to_flag(
  opt : StoredOption,
  global? : Bool = false,
) -> @argparse.FlagArg {
  let metadata = opt.metadata
  let env = metadata.env.map(fn(value) { value[:] })
  if has_short(opt) {
    @argparse.FlagArg(
      opt.name,
      short=metadata.short,
      about=metadata.description,
      env?,
      global~,
    )
  } else {
    @argparse.FlagArg(opt.name, about=metadata.description, env?, global~)
  }
}

///|
fn build_option_to_option_arg(
  opt : StoredOption,
  global? : Bool = false,
) -> @argparse.OptionArg {
  let metadata = opt.metadata
  let env = metadata.env.map(fn(value) { value[:] })
  let action = if metadata.multiple {
    @argparse.OptionAction::Append
  } else {
    @argparse.OptionAction::Set
  }
  match (has_short(opt), metadata.default_value, metadata.required) {
    (true, Some(dv), _) =>
      @argparse.OptionArg(
        opt.name,
        short=metadata.short,
        about=metadata.description,
        action~,
        env?,
        global~,
        default_values=[dv],
      )
    (true, None, true) =>
      @argparse.OptionArg(
        opt.name,
        short=metadata.short,
        about=metadata.description,
        action~,
        env?,
        global~,
        required=true,
      )
    (true, None, false) =>
      @argparse.OptionArg(
        opt.name,
        short=metadata.short,
        about=metadata.description,
        action~,
        env?,
        global~,
      )
    (false, Some(dv), _) =>
      @argparse.OptionArg(
        opt.name,
        about=metadata.description,
        action~,
        env?,
        global~,
        default_values=[dv],
      )
    (false, None, true) =>
      @argparse.OptionArg(
        opt.name,
        about=metadata.description,
        action~,
        env?,
        global~,
        required=true,
      )
    (false, None, false) =>
      @argparse.OptionArg(
        opt.name,
        about=metadata.description,
        action~,
        env?,
        global~,
      )
  }
}

///|
fn build_position(position : StoredPosition) -> @argparse.PositionArg {
  let metadata = position.metadata
  let num_args = match (metadata.required, metadata.multiple) {
    (true, false) => @argparse.ValueRange::single()
    (false, false) => @argparse.ValueRange(lower=0, upper=1)
    (true, true) => @argparse.ValueRange(lower=1)
    (false, true) => @argparse.ValueRange(lower=0)
  }
  @argparse.PositionArg(position.name, about=metadata.description, num_args~)
}

///|
fn fallback_to_help_when_no_match(cmd : CommandDef) -> Bool {
  cmd.run is None
}

///|
pub fn build_command(cmd : CommandDef) -> @argparse.Command {
  let flags : Array[@argparse.FlagArg] = []
  let options : Array[@argparse.OptionArg] = []
  for opt in cmd.options {
    match opt.metadata.type_ {
      BoolOpt => flags.push(build_option_to_flag(opt))
      StringOpt | IntOpt | Int64Opt | UIntOpt | UInt64Opt | DoubleOpt =>
        options.push(build_option_to_option_arg(opt))
    }
  }
  let positionals = cmd.positionals.map(fn(position) {
    build_position(position)
  })
  let subcommands = cmd.subcommands.map(fn(sub) { build_command(sub) })
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
