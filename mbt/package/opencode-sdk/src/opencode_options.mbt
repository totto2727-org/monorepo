///|
/// A recursively typed OpenCode configuration value.
pub(all) enum OpenCodeConfigValue {
  ConfigString(String)
  ConfigInt(Int)
  ConfigDouble(Double)
  ConfigBool(Bool)
  ConfigArray(Array[OpenCodeConfigValue])
  ConfigObject(Map[String, OpenCodeConfigValue])
} derive(Debug, Eq)

///|
/// An OpenCode configuration object serialized into `OPENCODE_CONFIG_CONTENT`.
pub type OpenCodeConfigObject = Map[String, OpenCodeConfigValue]

///|
/// Options shared by every thread created from an OpenCode client.
pub struct OpenCodeOptions {
  opencode_path_override : @path.Path?
  config : OpenCodeConfigObject?
  env : Map[String, String]?
} derive(Eq)

///|
/// Construct client-wide OpenCode CLI options.
pub fn OpenCodeOptions::OpenCodeOptions(
  opencode_path_override? : @path.Path,
  config? : OpenCodeConfigObject,
  env? : Map[String, String],
) -> OpenCodeOptions {
  { opencode_path_override, config, env }
}

///|
impl ToJson for OpenCodeConfigValue with fn to_json(self) -> Json {
  match self {
    ConfigString(value) => value.to_json()
    ConfigInt(value) => value.to_json()
    ConfigDouble(value) => value.to_json()
    ConfigBool(value) => value.to_json()
    ConfigArray(values) => values.to_json()
    ConfigObject(values) => values.to_json()
  }
}
