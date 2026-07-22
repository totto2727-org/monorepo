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
  metadata : Metadata
} derive(Debug)

///|
pub type OptionDef[T] = ArgDef[T, OptionMetadata]

///|
pub type PositionDef[T] = ArgDef[T, PositionMetadata]

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
  { name: self.name, metadata: self.metadata }
}

///|
trait ToStoredPosition {
  fn to_stored_position(Self) -> StoredPosition
}

///|
pub impl[T] ToStoredPosition for ArgDef[T, PositionMetadata] with fn to_stored_position(
  self,
) {
  { name: self.name, metadata: self.metadata }
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
  flags : Map[String, Bool]
  values : Map[String, Array[String]]
  subcommand : (String, Context)?
}

///|
pub(all) struct CliApp {
  name : String
  version : String
  description : String
  root_options : Array[StoredOption]
  commands : Array[CommandDef]
  load_config : (() -> Map[String, String] raise ConfigLoadFailure)?
}
