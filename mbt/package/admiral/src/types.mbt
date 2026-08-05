///|
pub enum OptionType {
  StringOpt
  BoolOpt
  IntOpt
  Int64Opt
  UIntOpt
  UInt64Opt
  DoubleOpt
} derive(Debug, Eq)

///|
pub impl Show for OptionType with fn output(self, logger) {
  match self {
    StringOpt => logger.write_string("StringOpt")
    BoolOpt => logger.write_string("BoolOpt")
    IntOpt => logger.write_string("IntOpt")
    Int64Opt => logger.write_string("Int64Opt")
    UIntOpt => logger.write_string("UIntOpt")
    UInt64Opt => logger.write_string("UInt64Opt")
    DoubleOpt => logger.write_string("DoubleOpt")
  }
}

///|
pub struct OptionMetadata {
  type_ : OptionType
  short : Char
  description : String
  env : String?
  required : Bool
  default_value : String?
  multiple : Bool
  interactive : Bool
} derive(Debug)

///|
pub struct PositionMetadata {
  type_ : OptionType
  description : String
  required : Bool
  multiple : Bool
  interactive : Bool
} derive(Debug)

///|
pub struct ArgDef[_, Metadata] {
  name : String
  config : String?
  metadata : Metadata
} derive(Debug)

///|
pub type OptionDef[T] = ArgDef[T, OptionMetadata]

///|
pub type PositionDef[T] = ArgDef[T, PositionMetadata]

///|
pub struct NonEmptyArray[T] {
  first : T
  rest : ArrayView[T]
  all : ReadOnlyArray[T]
} derive(Debug)

///|
type StoredOption = ArgDef[Unit, OptionMetadata]

///|
type StoredPosition = ArgDef[Unit, PositionMetadata]

///|
trait ToStoredOption {
  fn to_stored_option(Self) -> StoredOption
}

///|
pub impl[T] ToStoredOption for ArgDef[T, OptionMetadata] with fn to_stored_option(
  self,
) {
  { name: self.name, config: self.config, metadata: self.metadata }
}

///|
trait ToStoredPosition {
  fn to_stored_position(Self) -> StoredPosition
}

///|
pub impl[T] ToStoredPosition for ArgDef[T, PositionMetadata] with fn to_stored_position(
  self,
) {
  { name: self.name, config: self.config, metadata: self.metadata }
}

///|
pub struct CommandDef {
  name : String
  description : String
  options : Array[StoredOption]
  positionals : Array[StoredPosition]
  examples : Array[String]
  subcommands : Array[CommandDef]
  interactive : (async (InteractiveContext) -> Unit)?
  run : (async (Context) -> Unit)?
}

///|
pub(all) suberror ConfigLoadFailure {
  ConfigLoadFailure(String)
} derive(Debug, Eq)

///|
pub impl Show for ConfigLoadFailure with fn output(self, logger) {
  match self {
    ConfigLoadFailure(message) => logger.write_string(message)
  }
}

///|
pub struct Context {
  flags : @immut_hashmap.HashMap[String, Bool]
  values : @immut_hashmap.HashMap[String, ReadOnlyArray[String]]
  sources : @immut_hashmap.HashMap[String, @argparse.ValueSource]
  config : @immut_hashmap.HashMap[String, Json]
  interactive_flags : @immut_hashmap.HashMap[String, Bool]
  interactive_values : @immut_hashmap.HashMap[String, ReadOnlyArray[String]]
  subcommand : (String, Context)?
}

///|
pub fn Context::Context(
  flags? : Map[String, Bool] = Map([]),
  values? : Map[String, Array[String]] = Map([]),
  sources? : Map[String, @argparse.ValueSource] = Map([]),
  config? : Map[String, Json] = Map([]),
  subcommand? : (String, Context)? = None,
) -> Context {
  Context::{
    flags: @immut_hashmap.from_iter(flags.iter()),
    values: @immut_hashmap.from_iter(
      values
      .iter()
      .map(fn(entry) {
        let (key, items) = entry
        (key, ReadOnlyArray::from_array(items))
      }),
    ),
    sources: @immut_hashmap.from_iter(sources.iter()),
    config: @immut_hashmap.from_iter(config.iter()),
    interactive_flags: @immut_hashmap.new(),
    interactive_values: @immut_hashmap.new(),
    subcommand,
  }
}

///|
/// Accumulates values selected by a command's interactive input callback.
/// Read `to_context()` before setting values to obtain the resolved argv, environment,
/// configuration, positional, and default values as initial input.
pub struct InteractiveContext {
  initial : Context
  flags : Map[String, Bool]
  values : Map[String, Array[String]]
}

///|
fn Context::with_interactive_values(
  self : Context,
  flags : Map[String, Bool],
  values : Map[String, Array[String]],
) -> Context {
  let subcommand = match self.subcommand {
    Some((name, context)) =>
      Some((name, context.with_interactive_values(flags, values)))
    None => None
  }
  Context::{
    ..self,
    interactive_flags: @immut_hashmap.from_iter(flags.iter()),
    interactive_values: @immut_hashmap.from_iter(
      values
      .iter()
      .map(entry => {
        let (key, items) = entry
        (key, ReadOnlyArray::from_array(items))
      }),
    ),
    subcommand,
  }
}

///|
/// Returns the current context, including values already selected by this callback.
pub fn InteractiveContext::to_context(self : InteractiveContext) -> Context {
  self.initial.with_interactive_values(self.flags, self.values)
}

///|
/// Replaces a boolean option with a value selected interactively.
pub fn InteractiveContext::set_bool(
  self : InteractiveContext,
  option : OptionDef[Bool],
  value : Bool,
) -> Unit {
  self.flags[option.name] = value
}

///|
/// Replaces a string option or positional with a value selected interactively.
pub fn[Metadata] InteractiveContext::set_string(
  self : InteractiveContext,
  argument : ArgDef[String, Metadata],
  value : String,
) -> Unit {
  self.values[argument.name] = [value]
}

///|
/// Replaces a repeated string option or positional with values selected interactively.
pub fn[Metadata] InteractiveContext::set_strings(
  self : InteractiveContext,
  argument : ArgDef[Array[String], Metadata],
  values : Array[String],
) -> Unit {
  self.values[argument.name] = values
}

///|
/// Replaces an integer option or positional with a value selected interactively.
pub fn[Metadata] InteractiveContext::set_int(
  self : InteractiveContext,
  argument : ArgDef[Int, Metadata],
  value : Int,
) -> Unit {
  self.values[argument.name] = [value.to_string()]
}

///|
/// Replaces repeated integer input with values selected interactively.
pub fn[Metadata] InteractiveContext::set_ints(
  self : InteractiveContext,
  argument : ArgDef[Array[Int], Metadata],
  values : Array[Int],
) -> Unit {
  self.values[argument.name] = values.map(value => value.to_string())
}

///|
/// Replaces a 64-bit integer input with a value selected interactively.
pub fn[Metadata] InteractiveContext::set_int64(
  self : InteractiveContext,
  argument : ArgDef[Int64, Metadata],
  value : Int64,
) -> Unit {
  self.values[argument.name] = [value.to_string()]
}

///|
/// Replaces repeated 64-bit integer input with values selected interactively.
pub fn[Metadata] InteractiveContext::set_int64s(
  self : InteractiveContext,
  argument : ArgDef[Array[Int64], Metadata],
  values : Array[Int64],
) -> Unit {
  self.values[argument.name] = values.map(value => value.to_string())
}

///|
/// Replaces an unsigned integer input with a value selected interactively.
pub fn[Metadata] InteractiveContext::set_uint(
  self : InteractiveContext,
  argument : ArgDef[UInt, Metadata],
  value : UInt,
) -> Unit {
  self.values[argument.name] = [value.to_string()]
}

///|
/// Replaces repeated unsigned integer input with values selected interactively.
pub fn[Metadata] InteractiveContext::set_uints(
  self : InteractiveContext,
  argument : ArgDef[Array[UInt], Metadata],
  values : Array[UInt],
) -> Unit {
  self.values[argument.name] = values.map(value => value.to_string())
}

///|
/// Replaces a 64-bit unsigned integer input with a value selected interactively.
pub fn[Metadata] InteractiveContext::set_uint64(
  self : InteractiveContext,
  argument : ArgDef[UInt64, Metadata],
  value : UInt64,
) -> Unit {
  self.values[argument.name] = [value.to_string()]
}

///|
/// Replaces repeated 64-bit unsigned integer input with values selected interactively.
pub fn[Metadata] InteractiveContext::set_uint64s(
  self : InteractiveContext,
  argument : ArgDef[Array[UInt64], Metadata],
  values : Array[UInt64],
) -> Unit {
  self.values[argument.name] = values.map(value => value.to_string())
}

///|
/// Replaces a floating-point input with a value selected interactively.
pub fn[Metadata] InteractiveContext::set_double(
  self : InteractiveContext,
  argument : ArgDef[Double, Metadata],
  value : Double,
) -> Unit {
  self.values[argument.name] = [value.to_string()]
}

///|
/// Replaces repeated floating-point input with values selected interactively.
pub fn[Metadata] InteractiveContext::set_doubles(
  self : InteractiveContext,
  argument : ArgDef[Array[Double], Metadata],
  values : Array[Double],
) -> Unit {
  self.values[argument.name] = values.map(value => value.to_string())
}

///|
fn InteractiveContext::InteractiveContext(
  context : Context,
) -> InteractiveContext {
  let flags : Map[String, Bool] = Map([])
  for name, value in context.interactive_flags {
    flags[name] = value
  }
  let values : Map[String, Array[String]] = Map([])
  for name, items in context.interactive_values {
    values[name] = items.iter().to_array()
  }
  { initial: context, flags, values }
}

///|
pub struct CliApp {
  name : String
  version : String
  description : String
  root_options : Array[StoredOption]
  root_positionals : Array[StoredPosition]
  commands : Array[CommandDef]
  interactive : (async (InteractiveContext) -> Unit)?
  run : (async (Context) -> Unit)?
  load_config : (() -> Map[String, Json] raise ConfigLoadFailure)?
}
