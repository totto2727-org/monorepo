///|
let default_config_path : String = "bw-config.json"

///|
let account_id_option : @admiral.OptionDef[String] = @admiral.string(
  "account-id",
  description="Cloudflare account ID",
  env="CLOUDFLARE_ACCOUNT_ID",
  config="account_id",
  required=true,
)

///|
let api_token_option : @admiral.OptionDef[String] = @admiral.string(
  "api-token",
  description="Cloudflare API token",
  env="CLOUDFLARE_API_TOKEN",
  config="api_token",
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
async fn load_config(
  process_args? : Array[String] = @env.args(),
) -> Map[String, Json] raise @admiral.ConfigLoadFailure {
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
    Object(object) => object
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
