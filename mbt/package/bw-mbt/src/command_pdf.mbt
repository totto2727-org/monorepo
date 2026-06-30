///|
let pdf_account_id_option = "account-id"

///|
let pdf_api_token_option = "api-token"

///|
let pdf_url_option = "url"

///|
let pdf_html_option = "html"

///|
let pdf_wait_until_option = "wait-until"

///|
let pdf_output_option = "output"

///|
let pdf_landscape_option = "landscape"

///|
let pdf_format_option = "format"

///|
struct PdfOptionsInput {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  output : String
  landscape : Bool
  format : String?
}

///|
struct PdfGotoOptions {
  waitUntil : String
}

///|
struct PdfRenderOptions {
  landscape : Bool?
  format : String?
}

///|
struct PdfBody {
  url : String?
  html : String?
  gotoOptions : PdfGotoOptions?
  pdfOptions : PdfRenderOptions?
}

///|
impl ToJson for PdfGotoOptions with fn to_json(self) -> Json {
  Json::object({ "waitUntil": self.waitUntil.to_json() })
}

///|
impl ToJson for PdfRenderOptions with fn to_json(self) -> Json {
  Json::object({
    "landscape": match self.landscape {
      Some(value) => value.to_json()
      None => Json::null()
    },
    "format": match self.format {
      Some(value) => value.to_json()
      None => Json::null()
    },
  })
}

///|
impl ToJson for PdfBody with fn to_json(self) -> Json {
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
    "pdfOptions": match self.pdfOptions {
      Some(value) => value.to_json()
      None => Json::null()
    },
  })
}

///|
fn pdf_command_def() -> @admiral.CommandDef {
  @admiral.command(name="pdf", description="Generate a PDF", options=[
    @admiral.string(pdf_account_id_option, description="Cloudflare account ID"),
    @admiral.string(pdf_api_token_option, description="Cloudflare API token"),
    @admiral.string(pdf_url_option, description="Target URL"),
    @admiral.string(pdf_html_option, description="Path to local HTML file"),
    @admiral.string(pdf_wait_until_option, description="Page load strategy"),
    @admiral.string(
      pdf_output_option,
      short='o',
      description="Output file path",
      required=true,
    ),
    @admiral.bool(pdf_landscape_option, description="Landscape orientation"),
    @admiral.string(pdf_format_option, description="Page format"),
  ])
}

///|
async fn pdf_options(matches : @argparse.Matches) -> PdfOptionsInput {
  {
    account_id: match matches.values.get(pdf_account_id_option) {
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
    api_token: match matches.values.get(pdf_api_token_option) {
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
    url: match matches.values.get(pdf_url_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    html: match matches.values.get(pdf_html_option) {
      Some([path, ..]) => Some(@fs.read_file(path).text())
      _ => None
    },
    wait_until: match matches.values.get(pdf_wait_until_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    output: match matches.values.get(pdf_output_option) {
      Some([value, ..]) => value
      _ => fail("missing required option: output")
    },
    landscape: matches.flags.get(pdf_landscape_option).unwrap_or(false),
    format: match matches.values.get(pdf_format_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
  }
}

///|
fn PdfBody::from_options(options : PdfOptionsInput) -> PdfBody raise {
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
    pdfOptions: if options.landscape || options.format is Some(_) {
      Some({
        landscape: if options.landscape {
          Some(true)
        } else {
          None
        },
        format: options.format,
      })
    } else {
      None
    },
  }
}

///|
async fn run_pdf(matches : @argparse.Matches) -> Unit {
  let options = pdf_options(matches)
  let body = PdfBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/pdf",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  write_binary(options.output, data, "PDF")
}
