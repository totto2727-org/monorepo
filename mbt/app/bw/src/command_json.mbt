///|
let json_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
  env="BW_URL",
  config="url",
)

///|
let json_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
  env="BW_HTML",
  config="html",
)

///|
let json_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
  env="BW_WAIT_UNTIL",
  config="wait_until",
)

///|
let json_prompt_option : @admiral.OptionDef[String] = @admiral.string(
  "prompt",
  description="Extraction prompt",
  env="BW_PROMPT",
  config="prompt",
  required=true,
)

///|
let json_schema_option : @admiral.OptionDef[String] = @admiral.string(
  "schema",
  description="Path to JSON Schema file",
  env="BW_SCHEMA",
  config="schema",
)

///|
let json_format_option : @admiral.OptionDef[String] = @admiral.string(
  "format",
  description="Output format: json, markdown, text",
  env="BW_FORMAT",
  config="format",
)

///|
let json_extract_response_success_lens : @lens.PresenceLens[Bool] = @lens.root()
  .bool("success")
  .optional()

///|
let json_extract_response_result_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("result")
  .optional()

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
  response_format : SchemaResponseFormat?
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
  response_format : SchemaResponseFormat?
}

///|
struct JsonExtractResponse {
  success : Bool
  result : Json?
}

///|
impl FromJson for JsonExtractResponse with fn from_json(json, _path) {
  let success_value = json_extract_response_success_lens.get(json) catch {
    _ => None
  }
  let success = match success_value {
    Some(value) => value
    None => false
  }
  let result = json_extract_response_result_lens.get(json) catch { _ => None }
  { success, result }
}

///|
let json_goto_wait_until_lens : @lens.Lens[String] = @lens.root().string(
  "waitUntil",
)

///|
let json_extract_body_url_lens : @lens.PresenceLens[String] = @lens.root()
  .string("url")
  .optional()

///|
let json_extract_body_html_lens : @lens.PresenceLens[String] = @lens.root()
  .string("html")
  .optional()

///|
let json_extract_body_goto_options_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("gotoOptions")
  .optional()

///|
let json_extract_body_prompt_lens : @lens.Lens[String] = @lens.root().string(
  "prompt",
)

///|
let json_extract_body_response_format_lens : @lens.PresenceLens[Json] = @lens.root()
  .json("response_format")
  .optional()

///|
impl ToJson for JsonGotoOptions with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  json_goto_wait_until_lens.set_or_abort(builder, self.waitUntil)
  builder.to_json()
}

///|
extend JsonGotoOptions with ToJson::{to_json}

///|
impl ToJson for JsonExtractBody with fn to_json(self) -> Json {
  let builder = @lens.JsonBuilder::JsonBuilder()
  json_extract_body_url_lens.set_or_abort(builder, self.url)
  json_extract_body_html_lens.set_or_abort(builder, self.html)
  json_extract_body_goto_options_lens.set_or_abort(
    builder,
    self.gotoOptions.map(fn(value) { value.to_json() }),
  )
  json_extract_body_prompt_lens.set_or_abort(builder, self.prompt)
  json_extract_body_response_format_lens.set_or_abort(
    builder,
    self.response_format.map(fn(value) { value.to_json() }),
  )
  builder.to_json()
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
      json_prompt_option, json_schema_option, json_format_option,
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
  let (html, response_format) = @async.with_task_group(group => {
    let html_task = group.spawn(() => {
      read_optional_file(context.get_string(json_html_option))
    })
    let schema_task = group.spawn(() => {
      match context.get_string(json_schema_option) {
        Some(path) => Some(schema_response_format(path))
        None => None
      }
    })
    (html_task.wait(), schema_task.wait())
  })
  {
    account_id: context.get_string_required(account_id_option),
    api_token: context.get_string_required(api_token_option),
    url: context.get_string(json_url_option),
    html,
    wait_until: context.get_string(json_wait_until_option),
    prompt: context.get_string_required(json_prompt_option),
    response_format,
    output_format: match context.get_string(json_format_option) {
      Some(value) => parse_json_extract_output_format(value)
      _ => RawJson
    },
  }
}

///|
fn json_extract_result(raw : String) -> Json raise {
  let document = @json.parse(raw) catch {
    error => fail("Invalid json response JSON: \{error}")
  }
  let response : JsonExtractResponse = @json.from_json(document) catch {
    _ => fail("Invalid json response")
  }
  guard response.success else { fail("Invalid json response") }
  match response.result {
    Some(result) => result
    None => fail("Invalid json response")
  }
}

///|
fn json_extract_result_text(raw : String) -> String raise {
  let result = json_extract_result(raw)
  match result {
    Json::String(value) => value
    _ => result.stringify()
  }
}

///|
fn json_extract_result_markdown(raw : String) -> String raise {
  let result = json_extract_result(raw)
  match result {
    Json::String(value) => value
    _ => "```json\n\{result.stringify()}\n```"
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
