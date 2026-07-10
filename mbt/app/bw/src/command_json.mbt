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
let json_format_option = "format"

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
    @admiral.string(
      json_prompt_option,
      description="Extraction prompt",
      required=true,
    ),
    @admiral.string(json_schema_option, description="Path to JSON Schema file"),
    @admiral.string(
      json_format_option,
      description="Output format: json, markdown, text",
    ),
  ])
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
  matches : @argparse.Matches,
) -> JsonExtractOptionsInput {
  {
    account_id: match matches.values.get(json_account_id_option) {
      Some([value, ..]) => value
      _ =>
        match @env.get_env_var(cloudflare_account_id_env) {
          Some(value) => value
          None =>
            fail(
              "account-id is required. Set CLOUDFLARE_ACCOUNT_ID or pass --account-id",
            )
        }
    },
    api_token: match matches.values.get(json_api_token_option) {
      Some([value, ..]) => value
      _ =>
        match @env.get_env_var(cloudflare_api_token_env) {
          Some(value) => value
          None =>
            fail(
              "api-token is required. Set CLOUDFLARE_API_TOKEN or pass --api-token",
            )
        }
    },
    url: match matches.values.get(json_url_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    html: match matches.values.get(json_html_option) {
      Some([path, ..]) => Some(@fs.read_file(path).text())
      _ => None
    },
    wait_until: match matches.values.get(json_wait_until_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    prompt: match matches.values.get(json_prompt_option) {
      Some([value, ..]) => value
      _ => fail("missing required option: prompt")
    },
    response_format: match matches.values.get(json_schema_option) {
      Some([path, ..]) => {
        let schema = @json.parse(@fs.read_file(path).text()) catch {
          error => fail("Invalid JSON schema file: \{error}")
        }
        Some(
          Json::object({ "schema": schema, "type": "json_schema".to_json() }),
        )
      }
      _ => None
    },
    output_format: match matches.values.get(json_format_option) {
      Some([value, ..]) => parse_json_extract_output_format(value)
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
  guard options.url is Some(_) || options.html is Some(_) else {
    fail("Either --url or --html is required")
  }
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
  println(format_json_extract_response(data.text(), options.output_format))
}
