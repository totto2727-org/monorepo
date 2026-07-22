///|
let default_config_path : String = "bw-config.json"

///|
let account_id_config_env : String = cloudflare_account_id_env

///|
let api_token_config_env : String = cloudflare_api_token_env

///|
let url_config_env = "BW_URL"

///|
let html_config_env = "BW_HTML"

///|
let wait_until_config_env = "BW_WAIT_UNTIL"

///|
let output_config_env = "BW_OUTPUT"

///|
let full_page_config_env = "BW_FULL_PAGE"

///|
let width_config_env = "BW_WIDTH"

///|
let height_config_env = "BW_HEIGHT"

///|
let landscape_config_env = "BW_LANDSCAPE"

///|
let format_config_env = "BW_FORMAT"

///|
let selector_config_env = "BW_SELECTOR"

///|
let prompt_config_env = "BW_PROMPT"

///|
let schema_config_env = "BW_SCHEMA"

///|
let id_config_env = "BW_CRAWL_ID"

///|
let limit_config_env = "BW_CRAWL_LIMIT"

///|
let depth_config_env = "BW_CRAWL_DEPTH"

///|
let formats_config_env = "BW_CRAWL_FORMATS"

///|
let visible_only_config_env = "BW_VISIBLE_ONLY"

///|
let internal_only_config_env = "BW_INTERNAL_ONLY"

///|
let account_id_option : @admiral.OptionDef[String] = @admiral.string(
  "account-id",
  description="Cloudflare account ID",
  env=account_id_config_env,
  required=true,
)

///|
let api_token_option : @admiral.OptionDef[String] = @admiral.string(
  "api-token",
  description="Cloudflare API token",
  env=api_token_config_env,
  required=true,
)

///|
let config_option : @admiral.OptionDef[String] = @admiral.string(
  "config",
  description="Path to JSON config file",
  default=Some(default_config_path),
)

///|
struct ConfigLoaderArgs {
  argv : Array[String]
  explicit_path : Bool
}

///|
fn config_loader_args(process_args : Array[String]) -> ConfigLoaderArgs {
  let argv = ["load"]
  let mut explicit_path = false
  let mut index = 1
  while index < process_args.length() {
    let argument = process_args[index]
    if argument == "--" {
      break
    } else if argument == "--config" {
      explicit_path = true
      argv.push(argument)
      if index + 1 < process_args.length() {
        argv.push(process_args[index + 1])
        index = index + 2
      } else {
        index = index + 1
      }
    } else if argument.has_prefix("--config=") {
      explicit_path = true
      argv.push(argument)
      index = index + 1
    } else {
      index = index + 1
    }
  }
  { argv, explicit_path }
}

///|
fn config_value_to_string(value : Json) -> String? {
  match value {
    Array(_) => None
    String(value) => Some(value)
    _ => Some(value.stringify())
  }
}

///|
fn parse_config_object(object : Map[String, Json]) -> Map[String, String] {
  let values : Map[String, String] = Map([])
  for entry in object.iter() {
    let (key, value) = entry
    match config_value_to_string(value) {
      Some(value) => values[key] = value
      None => ()
    }
  }
  values
}

///|
async fn load_config(
  process_args? : Array[String] = @env.args(),
) -> Map[String, String] raise @admiral.ConfigLoadFailure {
  let loader_args = config_loader_args(process_args)
  let config_path = Ref(default_config_path)
  let loader = @admiral.cli(name="bw-config-loader", commands=[
    @admiral.command(
      name="load",
      options=[config_option],
      run=Some(context => {
        config_path.val = context.get_string_required(config_option)
      }),
    ),
  ])
  loader.run(argv=Some(loader_args.argv), env=Map([])) catch {
    error => raise @admiral.ConfigLoadFailure(error.to_string())
  }
  let config_exists = @fs.exists(config_path.val) catch {
    error =>
      raise @admiral.ConfigLoadFailure(
        "failed to inspect config file '\{config_path.val}': \{error}",
      )
  }
  if !config_exists {
    if loader_args.explicit_path {
      raise @admiral.ConfigLoadFailure(
        "config file does not exist: \{config_path.val}",
      )
    }
    return Map([])
  }
  let text = @fs.read_file(config_path.val).text() catch {
    error =>
      raise @admiral.ConfigLoadFailure(
        "failed to read config file '\{config_path.val}': \{error}",
      )
  }
  let parsed = @json.parse(text) catch {
    error =>
      raise @admiral.ConfigLoadFailure(
        "invalid config JSON in '\{config_path.val}': \{error}",
      )
  }
  match parsed {
    Object(object) => parse_config_object(object)
    _ =>
      raise @admiral.ConfigLoadFailure("config file must contain a JSON object")
  }
}

///|
fn required_body_source(url : String?, html : String?) -> Unit raise {
  guard url is Some(_) || html is Some(_) else {
    fail("Either --url or --html is required")
  }
}

///|
async fn read_optional_file(path : String?) -> String? {
  match path {
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
