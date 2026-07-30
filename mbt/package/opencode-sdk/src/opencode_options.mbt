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
pub(all) struct OpenCodeOptions {
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
fn config_value_to_json(value : OpenCodeConfigValue) -> Json {
  match value {
    ConfigString(value) => value.to_json()
    ConfigInt(value) => value.to_json()
    ConfigDouble(value) => value.to_json()
    ConfigBool(value) => value.to_json()
    ConfigArray(values) => Json::array(values.map(config_value_to_json))
    ConfigObject(values) => config_object_to_json(values)
  }
}

///|
fn config_object_to_json(config : OpenCodeConfigObject) -> Json {
  let object : Map[String, Json] = Map([])
  for key, value in config {
    object[key] = config_value_to_json(value)
  }
  Json::object(object)
}
