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
struct JsonExtractOptionsInput {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  prompt : String
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
}

///|
impl ToJson for JsonGotoOptions with fn to_json(self) -> Json {
  Json::object({ "waitUntil": self.waitUntil.to_json() })
}

///|
impl ToJson for JsonExtractBody with fn to_json(self) -> Json {
  Json::object({
    "url": match self.url {
      Some(value) => value.to_json()
      None => Json::null()
    },
    "html": match self.html {
      Some(value) => value.to_json()
      None => Json::null()
    },
    "gotoOptions": match self.gotoOptions {
      Some(value) => value.to_json()
      None => Json::null()
    },
    "prompt": self.prompt.to_json(),
  })
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
  ])
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
