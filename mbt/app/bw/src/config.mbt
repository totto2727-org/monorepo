///|
let account_id_option : @admiral.OptionDef[String] = @admiral.string(
  "account-id",
  description="Cloudflare account ID",
)

///|
let api_token_option : @admiral.OptionDef[String] = @admiral.string(
  "api-token",
  description="Cloudflare API token",
)

///|
let config_option : @admiral.OptionDef[String] = @admiral.string(
  "config",
  description="Path to JSON config file",
)

///|
struct BwConfig {
  account_id : String?
  api_token : String?
  url : String?
  html : String?
  wait_until : String?
  output : String?
  full_page : Bool?
  width : Int?
  height : Int?
  landscape : Bool?
  format : String?
  selector : String?
  prompt : String?
  schema : String?
  id : String?
  limit : Int?
  depth : Int?
  formats : Array[String]?
  visible_only : Bool?
  internal_only : Bool?
}

///|
fn empty_config() -> BwConfig {
  {
    account_id: None,
    api_token: None,
    url: None,
    html: None,
    wait_until: None,
    output: None,
    full_page: None,
    width: None,
    height: None,
    landscape: None,
    format: None,
    selector: None,
    prompt: None,
    schema: None,
    id: None,
    limit: None,
    depth: None,
    formats: None,
    visible_only: None,
    internal_only: None,
  }
}

///|
fn config_string(object : Map[String, Json], key : String) -> String? raise {
  match object.get(key) {
    Some(String(value)) => Some(value)
    Some(_) => fail("config key '\{key}' must be a string")
    None => None
  }
}

///|
fn config_bool(object : Map[String, Json], key : String) -> Bool? raise {
  match object.get(key) {
    Some(True) => Some(true)
    Some(False) => Some(false)
    Some(_) => fail("config key '\{key}' must be a boolean")
    None => None
  }
}

///|
fn config_int(object : Map[String, Json], key : String) -> Int? raise {
  match object.get(key) {
    Some(Number(value, ..)) => Some(value.to_int())
    Some(_) => fail("config key '\{key}' must be a number")
    None => None
  }
}

///|
fn config_string_array(
  object : Map[String, Json],
  key : String,
) -> Array[String]? raise {
  match object.get(key) {
    Some(Array(items)) => {
      let values : Array[String] = []
      for item in items {
        match item {
          String(value) => values.push(value)
          _ => fail("config key '\{key}' must contain only strings")
        }
      }
      Some(values)
    }
    Some(_) => fail("config key '\{key}' must be an array of strings")
    None => None
  }
}

///|
fn parse_config_object(object : Map[String, Json]) -> BwConfig raise {
  {
    account_id: config_string(object, "account_id"),
    api_token: config_string(object, "api_token"),
    url: config_string(object, "url"),
    html: config_string(object, "html"),
    wait_until: config_string(object, "wait_until"),
    output: config_string(object, "output"),
    full_page: config_bool(object, "full_page"),
    width: config_int(object, "width"),
    height: config_int(object, "height"),
    landscape: config_bool(object, "landscape"),
    format: config_string(object, "format"),
    selector: config_string(object, "selector"),
    prompt: config_string(object, "prompt"),
    schema: config_string(object, "schema"),
    id: config_string(object, "id"),
    limit: config_int(object, "limit"),
    depth: config_int(object, "depth"),
    formats: config_string_array(object, "formats"),
    visible_only: config_bool(object, "visible_only"),
    internal_only: config_bool(object, "internal_only"),
  }
}

///|
async fn load_config(context : @admiral.Context) -> BwConfig {
  match context.get_string(config_option) {
    Some(path) => {
      let parsed = @json.parse(@fs.read_file(path).text()) catch {
        error if @async.is_being_cancelled() => raise error
        error => fail("Invalid config JSON: \{error}")
      }
      match parsed {
        Object(object) => parse_config_object(object)
        _ => fail("config file must contain a JSON object")
      }
    }
    _ => empty_config()
  }
}

///|
fn cli_string(
  context : @admiral.Context,
  option : @admiral.OptionDef[String],
) -> String? {
  context.get_string(option)
}

///|
fn cli_int(
  context : @admiral.Context,
  option : @admiral.OptionDef[Int],
) -> Int? raise {
  match context.get_int(option) {
    Some(value) => Some(value)
    None =>
      if context.values.contains(option.name) {
        fail("Invalid --\{option.name} value: expected an integer")
      } else {
        None
      }
  }
}

///|
fn merge_string(cli : String?, config : String?) -> String? {
  match cli {
    Some(value) => Some(value)
    None => config
  }
}

///|
fn merge_bool(cli : Bool, config : Bool?, default : Bool) -> Bool {
  if cli {
    true
  } else {
    config.unwrap_or(default)
  }
}

///|
fn merge_int(cli : Int?, config : Int?) -> Int? {
  match cli {
    Some(value) => Some(value)
    None => config
  }
}

///|
fn merge_string_array(
  cli : Array[String]?,
  config : Array[String]?,
) -> Array[String]? {
  match cli {
    Some(value) => Some(value)
    None => config
  }
}

///|
fn required_value(name : String, value : String?) -> String raise {
  match value {
    Some(value) => value
    None => fail("missing required option: \{name}")
  }
}

///|
fn required_body_source(url : String?, html : String?) -> Unit raise {
  guard url is Some(_) || html is Some(_) else {
    fail("Either --url or --html is required")
  }
}

///|
fn merged_account_id(
  context : @admiral.Context,
  config : BwConfig,
) -> String raise {
  match
    merge_string(cli_string(context, account_id_option), config.account_id) {
    Some(value) => value
    None =>
      match @env.get_env_var(cloudflare_account_id_env) {
        Some(value) => value
        None =>
          fail(
            "account-id is required. Set CLOUDFLARE_ACCOUNT_ID, pass --account-id, or set account_id in --config",
          )
      }
  }
}

///|
fn merged_api_token(
  context : @admiral.Context,
  config : BwConfig,
) -> String raise {
  match merge_string(cli_string(context, api_token_option), config.api_token) {
    Some(value) => value
    None =>
      match @env.get_env_var(cloudflare_api_token_env) {
        Some(value) => value
        None =>
          fail(
            "api-token is required. Set CLOUDFLARE_API_TOKEN, pass --api-token, or set api_token in --config",
          )
      }
  }
}

///|
async fn merged_html(
  context : @admiral.Context,
  option : @admiral.OptionDef[String],
  config : BwConfig,
) -> String? {
  match merge_string(cli_string(context, option), config.html) {
    Some(path) => Some(@fs.read_file(path).text())
    None => None
  }
}

///|
async fn schema_response_format(path : String) -> Json {
  let schema = @json.parse(@fs.read_file(path).text()) catch {
    error if @async.is_being_cancelled() => raise error
    error => fail("Invalid JSON schema file: \{error}")
  }
  Json::object({ "schema": schema, "type": "json_schema".to_json() })
}
