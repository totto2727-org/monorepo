fn serialize_config_overrides(
  config : CodexConfigObject,
) -> Array[String] raise CodexSdkError {
  let overrides : Array[String] = []
  flatten_config_overrides(ConfigObject(config), "", overrides)
  overrides
}

fn flatten_config_overrides(
  value : CodexConfigValue,
  prefix : String,
  overrides : Array[String],
) -> Unit raise CodexSdkError {
  match value {
    ConfigObject(object) => {
      if prefix == "" && object.is_empty() {
        return
      }
      if prefix != "" && object.is_empty() {
        overrides.push("\{prefix}={}")
        return
      }
      for key, child in object {
        guard key != "" else {
          raise InvalidConfig(
            path=prefix,
            message="Codex config override keys must be non-empty strings",
          )
        }
        let path = if prefix == "" { key } else { "\{prefix}.\{key}" }
        match child {
          ConfigObject(_) => flatten_config_overrides(child, path, overrides)
          _ => overrides.push("\{path}=\{to_toml_value(child, path)}")
        }
      }
    }
    _ =>
      if prefix == "" {
        raise InvalidConfig(
          path="",
          message="Codex config overrides must be a plain object",
        )
      } else {
        overrides.push("\{prefix}=\{to_toml_value(value, prefix)}")
      }
  }
}

fn to_toml_value(
  value : CodexConfigValue,
  path : String,
) -> String raise CodexSdkError {
  match value {
    ConfigString(text) => Json::string(text).stringify()
    ConfigInt(number) => number.to_string()
    ConfigDouble(number) => {
      guard !number.is_nan() && !number.is_inf() else {
        raise InvalidConfig(
          path=path,
          message="Codex config override must be a finite number",
        )
      }
      number.to_string()
    }
    ConfigBool(value) => if value { "true" } else { "false" }
    ConfigArray(values) =>
      "[\{values.mapi((index, item) => to_toml_value(item, "\{path}[\{index}]")).join(", ")}]"
    ConfigObject(object) => {
      let parts : Array[String] = []
      for key, child in object {
        guard key != "" else {
          raise InvalidConfig(
            path=path,
            message="Codex config override keys must be non-empty strings",
          )
        }
        parts.push(
          "\{format_toml_key(key)} = \{to_toml_value(child, "\{path}.\{key}")}",
        )
      }
      "{\{parts.join(", ")}}"
    }
  }
}

fn format_toml_key(key : String) -> String {
  let is_bare = key.iter().all(char =>
    char.is_ascii_alphabetic() ||
    char.is_ascii_digit() ||
    char == '-' ||
    char == '_')
  if is_bare { key } else { Json::string(key).stringify() }
}
