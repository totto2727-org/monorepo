///|
let json_account_id_option = "account-id"

///|
let json_api_token_option = "api-token"

///|
let json_url_option = "url"

///|
let json_html_option = "html"

///|
let json_wait_until_option = "wait-until"

///|
let json_prompt_option = "prompt"

///|
let json_schema_option = "schema"

///|
struct JsonExtractOptionsInput {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  prompt : String
  response_format : Json?
}

///|
struct JsonGotoOptions {
  waitUntil : String
}

///|
struct JsonExtractBody {
  url : String?
  html : String?
  gotoOptions : JsonGotoOptions?
  prompt : String
  response_format : Json?
}

///|
impl ToJson for JsonGotoOptions with fn to_json(self) -> Json {
  Json::object({ "waitUntil": self.waitUntil.to_json() })
}

///|
impl ToJson for JsonExtractBody with fn to_json(self) -> Json {
  let object : Map[String, Json] = Map([])
  put_json_if_some(
    object,
    "url",
    match self.url {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  put_json_if_some(
    object,
    "html",
    match self.html {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  put_json_if_some(
    object,
    "gotoOptions",
    match self.gotoOptions {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  object.set("prompt", self.prompt.to_json())
  put_json_if_some(object, "response_format", self.response_format)
  Json::object(object)
}

///|
fn json_extract_command_def() -> @admiral.CommandDef {
  @admiral.command(name="json", description="Extract structured data", options=[
    @admiral.string(json_account_id_option, description="Cloudflare account ID"),
    @admiral.string(json_api_token_option, description="Cloudflare API token"),
    @admiral.string(json_url_option, description="Target URL"),
    @admiral.string(json_html_option, description="Path to local HTML file"),
    @admiral.string(json_wait_until_option, description="Page load strategy"),
    @admiral.string(json_prompt_option, description="Extraction prompt"),
    @admiral.string(json_schema_option, description="Path to JSON Schema file"),
    @admiral.string(config_option, description="Path to JSON config file"),
  ])
}

///|
async fn json_extract_options(
  matches : @argparse.Matches,
) -> JsonExtractOptionsInput {
  let config = load_config(matches)
  {
    account_id: merged_account_id(matches, config),
    api_token: merged_api_token(matches, config),
    url: merge_string(cli_string(matches, json_url_option), config.url),
    html: merged_html(matches, json_html_option, config),
    wait_until: merge_string(
      cli_string(matches, json_wait_until_option),
      config.wait_until,
    ),
    prompt: required_value(
      "prompt",
      merge_string(cli_string(matches, json_prompt_option), config.prompt),
    ),
    response_format: match
      merge_string(cli_string(matches, json_schema_option), config.schema) {
      Some(path) => Some(schema_response_format(path))
      None => None
    },
  }
}

///|
fn JsonExtractBody::from_options(
  options : JsonExtractOptionsInput,
) -> JsonExtractBody raise {
  required_body_source(options.url, options.html)
  {
    url: options.url,
    html: options.html,
    gotoOptions: match options.wait_until {
      Some(value) => Some({ waitUntil: value })
      None => None
    },
    prompt: options.prompt,
    response_format: options.response_format,
  }
}

///|
async fn run_json_extract(matches : @argparse.Matches) -> Unit {
  let options = json_extract_options(matches)
  let body = JsonExtractBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/json",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  println(data.text())
}
