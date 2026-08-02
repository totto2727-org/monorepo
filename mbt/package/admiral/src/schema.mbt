///|
fn option_type_to_string(t : OptionType) -> String {
  match t {
    StringOpt => "string"
    BoolOpt => "bool"
    IntOpt => "int"
    Int64Opt => "int64"
    UIntOpt => "uint"
    UInt64Opt => "uint64"
    DoubleOpt => "double"
  }
}

///|
priv struct OptionSchema {
  option : StoredOption
}

///|
let option_schema_type_lens : @lens.Lens[String] = @lens.root().string("type")

///|
let option_schema_description_lens : @lens.Lens[String] = @lens.root().string(
  "description",
)

///|
let option_schema_required_lens : @lens.Lens[Bool] = @lens.root().bool(
  "required",
)

///|
let option_schema_multiple_lens : @lens.Lens[Bool] = @lens.root().bool(
  "multiple",
)

///|
let option_schema_style_lens : @lens.PresenceLens[String] = @lens.root()
  .string("style")
  .optional()

///|
let option_schema_short_lens : @lens.PresenceLens[String] = @lens.root()
  .string("short")
  .optional()

///|
let option_schema_env_lens : @lens.PresenceLens[String] = @lens.root()
  .string("env")
  .optional()

///|
let option_schema_config_lens : @lens.PresenceLens[String] = @lens.root()
  .string("config")
  .optional()

///|
let option_schema_default_lens : @lens.PresenceLens[String] = @lens.root()
  .string("default")
  .optional()

///|
impl ToJson for OptionSchema with fn to_json(self) -> Json {
  let option = self.option
  let metadata = option.metadata
  let builder = @lens.JsonBuilder::JsonBuilder()
  option_schema_type_lens.set_or_abort(
    builder,
    option_type_to_string(metadata.type_),
  )
  option_schema_description_lens.set_or_abort(builder, metadata.description)
  option_schema_required_lens.set_or_abort(builder, metadata.required)
  option_schema_multiple_lens.set_or_abort(builder, metadata.multiple)
  option_schema_style_lens.set_or_abort(
    builder,
    if metadata.type_ == BoolOpt {
      Some("flag")
    } else {
      None
    },
  )
  option_schema_short_lens.set_or_abort(
    builder,
    if metadata.short != no_short {
      Some(metadata.short.to_string())
    } else {
      None
    },
  )
  option_schema_env_lens.set_or_abort(builder, metadata.env)
  option_schema_config_lens.set_or_abort(builder, option.config)
  option_schema_default_lens.set_or_abort(builder, metadata.default_value)
  builder.to_json()
}

///|
extend OptionSchema with ToJson::{to_json}

///|
priv struct PositionSchema {
  position : StoredPosition
}

///|
let position_schema_type_lens : @lens.Lens[String] = @lens.root().string("type")

///|
let position_schema_description_lens : @lens.Lens[String] = @lens.root().string(
  "description",
)

///|
let position_schema_required_lens : @lens.Lens[Bool] = @lens.root().bool(
  "required",
)

///|
let position_schema_multiple_lens : @lens.Lens[Bool] = @lens.root().bool(
  "multiple",
)

///|
let position_schema_config_lens : @lens.PresenceLens[String] = @lens.root()
  .string("config")
  .optional()

///|
impl ToJson for PositionSchema with fn to_json(self) -> Json {
  let position = self.position
  let metadata = position.metadata
  let builder = @lens.JsonBuilder::JsonBuilder()
  position_schema_type_lens.set_or_abort(
    builder,
    option_type_to_string(metadata.type_),
  )
  position_schema_description_lens.set_or_abort(builder, metadata.description)
  position_schema_required_lens.set_or_abort(builder, metadata.required)
  position_schema_multiple_lens.set_or_abort(builder, metadata.multiple)
  position_schema_config_lens.set_or_abort(builder, position.config)
  builder.to_json()
}

///|
extend PositionSchema with ToJson::{to_json}

///|
fn generate_example(cmd_path : String, options : Array[StoredOption]) -> String {
  let parts : Array[String] = [cmd_path]
  for opt in options {
    if opt.metadata.required {
      parts.push("--" + opt.name + " <" + opt.name + ">")
    }
  }
  parts.join(" ")
}

///|
priv struct CommandSchema {
  command : CommandDef
  path : String
}

///|
let command_schema_description_lens : @lens.Lens[String] = @lens.root().string(
  "description",
)

///|
let command_schema_options_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("options")
  .optional()

///|
let command_schema_positionals_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("positionals")
  .optional()

///|
let command_schema_examples_lens : @lens.PresenceLens[Array[String]] = @lens.root()
  .string("examples")
  .array()
  .optional()

///|
let command_schema_commands_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("commands")
  .optional()

///|
impl ToJson for CommandSchema with fn to_json(self) -> Json {
  let command = self.command
  let builder = @lens.JsonBuilder::JsonBuilder()
  command_schema_description_lens.set_or_abort(builder, command.description)
  let options : Map[String, Json] = Map([])
  for option in command.options {
    options[option.name] = OptionSchema::{ option, }.to_json()
  }
  command_schema_options_lens.set_or_abort(
    builder,
    if options.is_empty() {
      None
    } else {
      Some(options.to_json())
    },
  )
  let positionals : Map[String, Json] = Map([])
  for position in command.positionals {
    positionals[position.name] = PositionSchema::{ position, }.to_json()
  }
  command_schema_positionals_lens.set_or_abort(
    builder,
    if positionals.is_empty() {
      None
    } else {
      Some(positionals.to_json())
    },
  )
  command_schema_examples_lens.set_or_abort(
    builder,
    if command.examples.length() > 0 {
      Some(command.examples)
    } else if command.options.length() > 0 || command.positionals.length() > 0 {
      Some([generate_example(self.path, command.options)])
    } else {
      None
    },
  )
  let subcommands : Map[String, Json] = Map([])
  for subcommand in command.subcommands {
    subcommands[subcommand.name] = CommandSchema::{
      command: subcommand,
      path: self.path + " " + subcommand.name,
    }.to_json()
  }
  command_schema_commands_lens.set_or_abort(
    builder,
    if subcommands.is_empty() {
      None
    } else {
      Some(subcommands.to_json())
    },
  )
  builder.to_json()
}

///|
extend CommandSchema with ToJson::{to_json}

///|
let cli_schema_name_lens : @lens.Lens[String] = @lens.root().string("name")

///|
let cli_schema_version_lens : @lens.Lens[String] = @lens.root().string(
  "version",
)

///|
let cli_schema_description_lens : @lens.Lens[String] = @lens.root().string(
  "description",
)

///|
let cli_schema_options_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("options")
  .optional()

///|
let cli_schema_positionals_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("positionals")
  .optional()

///|
let cli_schema_commands_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("commands")
  .optional()

///|
pub impl ToJson for CliApp with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  cli_schema_name_lens.set_or_abort(builder, self.name)
  cli_schema_version_lens.set_or_abort(builder, self.version)
  cli_schema_description_lens.set_or_abort(builder, self.description)
  let options : Map[String, Json] = Map([])
  for option in self.root_options {
    options[option.name] = OptionSchema::{ option, }.to_json()
  }
  cli_schema_options_lens.set_or_abort(
    builder,
    if options.is_empty() {
      None
    } else {
      Some(options.to_json())
    },
  )
  let positionals : Map[String, Json] = Map([])
  for position in self.root_positionals {
    positionals[position.name] = PositionSchema::{ position, }.to_json()
  }
  cli_schema_positionals_lens.set_or_abort(
    builder,
    if positionals.is_empty() {
      None
    } else {
      Some(positionals.to_json())
    },
  )
  let commands : Map[String, Json] = Map([])
  for command in self.commands {
    commands[command.name] = CommandSchema::{
      command,
      path: self.name + " " + command.name,
    }.to_json()
  }
  cli_schema_commands_lens.set_or_abort(
    builder,
    if commands.is_empty() {
      None
    } else {
      Some(commands.to_json())
    },
  )
  builder.to_json()
}

///|
extend CliApp with ToJson::{to_json}

///|
pub fn CliApp::render_schema(self : CliApp) -> String {
  self.to_json().stringify()
}
