///|
let snapshot_account_id_option = "account-id"

///|
let snapshot_api_token_option = "api-token"

///|
let snapshot_url_option = "url"

///|
let snapshot_html_option = "html"

///|
let snapshot_wait_until_option = "wait-until"

///|
let snapshot_output_option = "output"

///|
let snapshot_full_page_option = "full-page"

///|
struct SnapshotOptionsInput {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  output : String
  full_page : Bool
}

///|
struct SnapshotGotoOptions {
  waitUntil : String
}

///|
struct SnapshotCaptureOptions {
  fullPage : Bool
}

///|
struct SnapshotBody {
  url : String?
  html : String?
  gotoOptions : SnapshotGotoOptions?
  screenshotOptions : SnapshotCaptureOptions?
}

///|
impl ToJson for SnapshotGotoOptions with fn to_json(self) -> Json {
  Json::object({ "waitUntil": self.waitUntil.to_json() })
}

///|
impl ToJson for SnapshotCaptureOptions with fn to_json(self) -> Json {
  Json::object({ "fullPage": self.fullPage.to_json() })
}

///|
impl ToJson for SnapshotBody with fn to_json(self) -> Json {
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
  put_json_if_some(
    object,
    "screenshotOptions",
    match self.screenshotOptions {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  Json::object(object)
}

///|
fn snapshot_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="snapshot",
    description="Capture both HTML and screenshot",
    options=[
      @admiral.string(
        snapshot_account_id_option,
        description="Cloudflare account ID",
      ),
      @admiral.string(
        snapshot_api_token_option,
        description="Cloudflare API token",
      ),
      @admiral.string(snapshot_url_option, description="Target URL"),
      @admiral.string(
        snapshot_html_option,
        description="Path to local HTML file",
      ),
      @admiral.string(
        snapshot_wait_until_option,
        description="Page load strategy",
      ),
      @admiral.string(
        snapshot_output_option,
        short='o',
        description="Output directory",
      ),
      @admiral.bool(
        snapshot_full_page_option,
        description="Capture entire page",
      ),
      @admiral.string(config_option, description="Path to JSON config file"),
    ],
  )
}

///|
async fn snapshot_options(matches : @argparse.Matches) -> SnapshotOptionsInput {
  let config = load_config(matches)
  {
    account_id: merged_account_id(matches, config),
    api_token: merged_api_token(matches, config),
    url: merge_string(cli_string(matches, snapshot_url_option), config.url),
    html: merged_html(matches, snapshot_html_option, config),
    wait_until: merge_string(
      cli_string(matches, snapshot_wait_until_option),
      config.wait_until,
    ),
    output: required_value(
      "output",
      merge_string(cli_string(matches, snapshot_output_option), config.output),
    ),
    full_page: merge_bool(
      matches.flags.get(snapshot_full_page_option).unwrap_or(false),
      config.full_page,
      false,
    ),
  }
}

///|
fn SnapshotBody::from_options(
  options : SnapshotOptionsInput,
) -> SnapshotBody raise {
  required_body_source(options.url, options.html)
  {
    url: options.url,
    html: options.html,
    gotoOptions: match options.wait_until {
      Some(value) => Some({ waitUntil: value })
      None => None
    },
    screenshotOptions: if options.full_page {
      Some({ fullPage: true })
    } else {
      None
    },
  }
}

///|
fn snapshot_result(data : &@io.Data) -> (String, Bytes) raise {
  let parsed = @json.parse(data.text()) catch {
    error => fail("Invalid snapshot response JSON: \{error}")
  }
  match parsed {
    Object({ "success": True, "result": Object(result), .. }) =>
      match (result.get("content"), result.get("screenshot")) {
        (Some(String(content)), Some(String(screenshot))) => {
          let screenshot_bytes = @base64.std_decode2bytes(screenshot) catch {
            error => fail("Invalid snapshot screenshot data: \{error}")
          }
          (content, screenshot_bytes)
        }
        _ => fail("Invalid snapshot response: missing content or screenshot")
      }
    _ => fail("Invalid snapshot response")
  }
}

///|
async fn run_snapshot(matches : @argparse.Matches) -> Unit {
  let options = snapshot_options(matches)
  let body = SnapshotBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/snapshot",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  let (content, screenshot) = snapshot_result(data)
  write_snapshot(options.output, content, screenshot)
}
