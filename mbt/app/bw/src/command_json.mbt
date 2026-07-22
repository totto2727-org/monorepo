///|
let json_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
)

///|
let json_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
)

///|
let json_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
)

///|
let json_prompt_option : @admiral.OptionDef[String] = @admiral.string(
  "prompt",
  description="Extraction prompt",
)

///|
let json_schema_option : @admiral.OptionDef[String] = @admiral.string(
  "schema",
  description="Path to JSON Schema file",
)

///|
let json_format_option : @admiral.OptionDef[String] = @admiral.string(
  "format",
  description="Output format: json, markdown, text",
)

///|
enum JsonExtractOutputFormat {
  RawJson
  Markdown
  Text
}

///|
struct JsonExtractOptionsInput {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  prompt : String
  response_format : Json?
  output_format : JsonExtractOutputFormat
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
extend JsonGotoOptions with ToJson::{to_json}

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
extend JsonExtractBody with ToJson::{to_json}

///|
fn json_extract_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="json",
    description="Extract structured data",
    options=[
      account_id_option, api_token_option, json_url_option, json_html_option, json_wait_until_option,
      json_prompt_option, json_schema_option, json_format_option, config_option,
    ],
    run=Some(run),
  )
}

///|
fn parse_json_extract_output_format(
  value : String,
) -> JsonExtractOutputFormat raise {
  match value {
    "json" => RawJson
    "markdown" => Markdown
    "text" => Text
    _ =>
      fail("Invalid --format value: \{value}. Expected json, markdown, or text")
  }
}

///|
async fn json_extract_options(
  context : @admiral.Context,
) -> JsonExtractOptionsInput {
  let config = load_config(context)
  let (html, response_format) = @async.with_task_group(group => {
    let html_task = group.spawn(() => {
      merged_html(context, json_html_option, config)
    })
    let schema_task = group.spawn(() => {
      match
        merge_string(cli_string(context, json_schema_option), config.schema) {
        Some(path) => Some(schema_response_format(path))
        None => None
      }
    })
    (html_task.wait(), schema_task.wait())
  })
  {
    account_id: merged_account_id(context, config),
    api_token: merged_api_token(context, config),
    url: merge_string(cli_string(context, json_url_option), config.url),
    html,
    wait_until: merge_string(
      cli_string(context, json_wait_until_option),
      config.wait_until,
    ),
    prompt: required_value(
      "prompt",
      merge_string(cli_string(context, json_prompt_option), config.prompt),
    ),
    response_format,
    output_format: match
      merge_string(cli_string(context, json_format_option), config.format) {
      Some(value) => parse_json_extract_output_format(value)
      _ => RawJson
    },
  }
}

///|
fn json_extract_result(raw : String) -> Json raise {
  let parsed = @json.parse(raw) catch {
    error => fail("Invalid json response JSON: \{error}")
  }
  match parsed {
    Object({ "success": True, "result": result, .. }) => result
    _ => fail("Invalid json response")
  }
}

///|
fn json_extract_result_text(raw : String) -> String raise {
  match json_extract_result(raw) {
    String(value) => value
    result => result.stringify()
  }
}

///|
fn json_extract_result_markdown(raw : String) -> String raise {
  match json_extract_result(raw) {
    String(value) => value
    result => "```json\n\{result.stringify()}\n```"
  }
}

///|
fn format_json_extract_response(
  raw : String,
  output_format : JsonExtractOutputFormat,
) -> String raise {
  match output_format {
    RawJson => raw
    Markdown => json_extract_result_markdown(raw)
    Text => json_extract_result_text(raw)
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
async fn run_json_extract(context : @admiral.Context) -> Unit {
  let options = json_extract_options(context)
  let body = JsonExtractBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/json",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  println(format_json_extract_response(data.text(), options.output_format))
}
