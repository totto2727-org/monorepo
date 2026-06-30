///|
let crawl_account_id_option = "account-id"

///|
let crawl_api_token_option = "api-token"

///|
let crawl_url_option = "url"

///|
let crawl_html_option = "html"

///|
let crawl_wait_until_option = "wait-until"

///|
let crawl_output_option = "output"

///|
let crawl_limit_option = "limit"

///|
let crawl_depth_option = "depth"

///|
let crawl_format_option = "format"

///|
let crawl_id_option = "id"

///|
struct CrawlStartOptionsInput {
  account_id : String
  api_token : String
  url : String?
  html : String?
  wait_until : String?
  output : String?
  limit : Int?
  depth : Int?
  formats : Array[String]?
}

///|
struct CrawlGetOptionsInput {
  account_id : String
  api_token : String
  id : String
  output : String?
}

///|
struct CrawlGotoOptions {
  waitUntil : String
}

///|
struct CrawlStartBody {
  url : String?
  html : String?
  gotoOptions : CrawlGotoOptions?
  limit : Int?
  depth : Int?
  formats : Array[String]?
}

///|
impl ToJson for CrawlGotoOptions with fn to_json(self) -> Json {
  Json::object({ "waitUntil": self.waitUntil.to_json() })
}

///|
impl ToJson for CrawlStartBody with fn to_json(self) -> Json {
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
    "limit": match self.limit {
      Some(value) => value.to_json()
      None => Json::null()
    },
    "depth": match self.depth {
      Some(value) => value.to_json()
      None => Json::null()
    },
    "formats": match self.formats {
      Some(value) => value.to_json()
      None => Json::null()
    },
  })
}

///|
fn crawl_command_def() -> @admiral.CommandDef {
  @admiral.command(name="crawl", description="Manage async crawl jobs", subcommands=[
    @admiral.command(name="start", description="Start a crawl job", options=[
      @admiral.string(
        crawl_account_id_option,
        description="Cloudflare account ID",
      ),
      @admiral.string(
        crawl_api_token_option,
        description="Cloudflare API token",
      ),
      @admiral.string(crawl_url_option, description="Target URL"),
      @admiral.string(crawl_html_option, description="Path to local HTML file"),
      @admiral.string(crawl_wait_until_option, description="Page load strategy"),
      @admiral.string(
        crawl_output_option,
        short='o',
        description="Output file path",
      ),
      @admiral.int(crawl_limit_option, description="Max pages to crawl"),
      @admiral.int(crawl_depth_option, description="Max link depth"),
      @admiral.string(
        crawl_format_option,
        description="Output formats: html,markdown,json",
      ),
    ]),
    @admiral.command(name="status", description="Check crawl job status", options=[
      @admiral.string(
        crawl_account_id_option,
        description="Cloudflare account ID",
      ),
      @admiral.string(
        crawl_api_token_option,
        description="Cloudflare API token",
      ),
      @admiral.string(
        crawl_id_option,
        description="Crawl job ID",
        required=true,
      ),
    ]),
    @admiral.command(name="results", description="Retrieve crawl results", options=[
      @admiral.string(
        crawl_account_id_option,
        description="Cloudflare account ID",
      ),
      @admiral.string(
        crawl_api_token_option,
        description="Cloudflare API token",
      ),
      @admiral.string(
        crawl_id_option,
        description="Crawl job ID",
        required=true,
      ),
      @admiral.string(
        crawl_output_option,
        short='o',
        description="Output file path",
      ),
    ]),
  ])
}

///|
fn split_csv(value : String) -> Array[String] {
  value.split(",").map(fn(item) { item.to_owned() }).collect()
}

///|
async fn crawl_start_options(
  matches : @argparse.Matches,
) -> CrawlStartOptionsInput {
  {
    account_id: match matches.values.get(crawl_account_id_option) {
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
    api_token: match matches.values.get(crawl_api_token_option) {
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
    url: match matches.values.get(crawl_url_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    html: match matches.values.get(crawl_html_option) {
      Some([path, ..]) => Some(@fs.read_file(path).text())
      _ => None
    },
    wait_until: match matches.values.get(crawl_wait_until_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    output: match matches.values.get(crawl_output_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
    limit: match matches.values.get(crawl_limit_option) {
      Some([value, ..]) => Some(@string.parse_int(value))
      _ => None
    },
    depth: match matches.values.get(crawl_depth_option) {
      Some([value, ..]) => Some(@string.parse_int(value))
      _ => None
    },
    formats: match matches.values.get(crawl_format_option) {
      Some([value, ..]) => Some(split_csv(value))
      _ => None
    },
  }
}

///|
fn CrawlStartBody::from_options(
  options : CrawlStartOptionsInput,
) -> CrawlStartBody raise {
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
    limit: options.limit,
    depth: options.depth,
    formats: options.formats,
  }
}

///|
async fn run_crawl_start(matches : @argparse.Matches) -> Unit {
  let options = crawl_start_options(matches)
  let body = CrawlStartBody::from_options(options)
  let (code, reason, data) = post_json(
    options.account_id,
    options.api_token,
    "/crawl",
    body.to_json(),
  )
  ensure_success(code, reason, data)
  write_text_or_stdout(options.output, data.text())
}

///|
fn crawl_get_options(matches : @argparse.Matches) -> CrawlGetOptionsInput raise {
  {
    account_id: match matches.values.get(crawl_account_id_option) {
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
    api_token: match matches.values.get(crawl_api_token_option) {
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
    id: match matches.values.get(crawl_id_option) {
      Some([value, ..]) => value
      _ => fail("missing required option: id")
    },
    output: match matches.values.get(crawl_output_option) {
      Some([value, ..]) => Some(value)
      _ => None
    },
  }
}

///|
async fn run_crawl_get(
  matches : @argparse.Matches,
  suffix : String,
  output : Bool,
) -> Unit {
  let options = crawl_get_options(matches)
  let (code, reason, data) = get_json(
    options.account_id,
    options.api_token,
    "/crawl/\{options.id}\{suffix}",
  )
  ensure_success(code, reason, data)
  if output {
    write_text_or_stdout(options.output, data.text())
  } else {
    println(data.text())
  }
}
