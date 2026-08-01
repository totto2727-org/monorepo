///|
pub(all) enum OptionType {
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
} derive(Debug)

///|
pub struct PositionMetadata {
  type_ : OptionType
  description : String
  required : Bool
  multiple : Bool
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
pub(all) struct CommandDef {
  name : String
  description : String
  options : Array[StoredOption]
  positionals : Array[StoredPosition]
  examples : Array[String]
  subcommands : Array[CommandDef]
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
pub(all) struct Context {
  flags : @immut_hashmap.HashMap[String, Bool]
  values : @immut_hashmap.HashMap[String, ReadOnlyArray[String]]
  sources : @immut_hashmap.HashMap[String, @argparse.ValueSource]
  config : @immut_hashmap.HashMap[String, Json]
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
      values.iter().map(fn(entry) {
        let (key, items) = entry
        (key, ReadOnlyArray::from_array(items))
      }),
    ),
    sources: @immut_hashmap.from_iter(sources.iter()),
    config: @immut_hashmap.from_iter(config.iter()),
    subcommand,
  }
}

///|
pub(all) struct CliApp {
  name : String
  version : String
  description : String
  root_options : Array[StoredOption]
  root_positionals : Array[StoredPosition]
  commands : Array[CommandDef]
  run : (async (Context) -> Unit)?
  load_config : (() -> Map[String, Json] raise ConfigLoadFailure)?
}
