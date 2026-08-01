///|
let snapshot_url_option : @admiral.OptionDef[String] = @admiral.string(
  "url",
  description="Target URL",
  env="BW_URL",
  config="url",
)

///|
let snapshot_html_option : @admiral.OptionDef[String] = @admiral.string(
  "html",
  description="Path to local HTML file",
  env="BW_HTML",
  config="html",
)

///|
let snapshot_wait_until_option : @admiral.OptionDef[String] = @admiral.string(
  "wait-until",
  description="Page load strategy",
  env="BW_WAIT_UNTIL",
  config="wait_until",
)

///|
let snapshot_output_option : @admiral.OptionDef[String] = @admiral.string(
  "output",
  short='o',
  description="Output directory",
  env="BW_OUTPUT",
  config="output",
  required=true,
)

///|
let snapshot_full_page_option : @admiral.OptionDef[Bool] = @admiral.bool(
  "full-page",
  description="Capture entire page",
  env="BW_FULL_PAGE",
  config="full_page",
)

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
struct SnapshotResponseResult {
  content : String?
  screenshot : String?
}

///|
impl FromJson for SnapshotResponseResult with fn from_json(json, _path) {
  let content = @lens.root().string("content").optional().get(json) catch {
      _ => None
    }
  let screenshot = @lens.root().string("screenshot").optional().get(json) catch {
      _ => None
    }
  { content, screenshot }
}

///|
struct SnapshotResponse {
  success : Bool
  result : SnapshotResponseResult?
}

///|
impl FromJson for SnapshotResponse with fn from_json(json, _path) {
  let success_value = @lens.root().bool("success").optional().get(json) catch {
      _ => None
    }
  let success = match success_value {
    Some(value) => value
    None => false
  }
  let result_value = @lens.root().json("result").optional().get(json) catch {
      _ => None
    }
  let result = match result_value {
    Some(value) => Some((@json.from_json(value) : SnapshotResponseResult))
    None => None
  }
  { success, result }
}

///|
impl ToJson for SnapshotGotoOptions with fn to_json(self) -> Json {
  Json::object({ "waitUntil": self.waitUntil.to_json() })
}

///|
extend SnapshotGotoOptions with ToJson::{to_json}

///|
impl ToJson for SnapshotCaptureOptions with fn to_json(self) -> Json {
  Json::object({ "fullPage": self.fullPage.to_json() })
}

///|
extend SnapshotCaptureOptions with ToJson::{to_json}

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
extend SnapshotBody with ToJson::{to_json}

///|
fn snapshot_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="snapshot",
    description="Capture both HTML and screenshot",
    options=[
      account_id_option, api_token_option, snapshot_url_option, snapshot_html_option,
      snapshot_wait_until_option, snapshot_output_option, snapshot_full_page_option,
    ],
    run=Some(run),
  )
}

///|
async fn snapshot_options(context : @admiral.Context) -> SnapshotOptionsInput {
  {
    account_id: context.get_string_required(account_id_option),
    api_token: context.get_string_required(api_token_option),
    url: context.get_string(snapshot_url_option),
    html: read_optional_file(context.get_string(snapshot_html_option)),
    wait_until: context.get_string(snapshot_wait_until_option),
    output: context.get_string_required(snapshot_output_option),
    full_page: context.get_bool(snapshot_full_page_option),
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
  let document = @json.parse(data.text()) catch {
    error => fail("Invalid snapshot response JSON: \{error}")
  }
  let response : SnapshotResponse = @json.from_json(document) catch {
    _ => fail("Invalid snapshot response")
  }
  guard response.success else { fail("Invalid snapshot response") }
  let result = match response.result {
    Some(value) => value
    None => fail("Invalid snapshot response: missing content or screenshot")
  }
  let content = match result.content {
    Some(value) => value
    None => fail("Invalid snapshot response: missing content or screenshot")
  }
  let screenshot = match result.screenshot {
    Some(value) => value
    None => fail("Invalid snapshot response: missing content or screenshot")
  }
  let screenshot_bytes = @base64.std_decode2bytes(screenshot) catch {
    error => fail("Invalid snapshot screenshot data: \{error}")
  }
  (content, screenshot_bytes)
}

///|
async fn run_snapshot(context : @admiral.Context) -> Unit {
  let options = snapshot_options(context)
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
