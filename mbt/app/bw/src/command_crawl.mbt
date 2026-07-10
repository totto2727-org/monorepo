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
    "limit",
    match self.limit {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  put_json_if_some(
    object,
    "depth",
    match self.depth {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  put_json_if_some(
    object,
    "formats",
    match self.formats {
      Some(value) => Some(value.to_json())
      None => None
    },
  )
  Json::object(object)
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
      @admiral.string(config_option, description="Path to JSON config file"),
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
      @admiral.string(crawl_id_option, description="Crawl job ID"),
      @admiral.string(config_option, description="Path to JSON config file"),
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
      @admiral.string(crawl_id_option, description="Crawl job ID"),
      @admiral.string(
        crawl_output_option,
        short='o',
        description="Output file path",
      ),
      @admiral.string(config_option, description="Path to JSON config file"),
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
  let config = load_config(matches)
  {
    account_id: merged_account_id(matches, config),
    api_token: merged_api_token(matches, config),
    url: merge_string(cli_string(matches, crawl_url_option), config.url),
    html: merged_html(matches, crawl_html_option, config),
    wait_until: merge_string(
      cli_string(matches, crawl_wait_until_option),
      config.wait_until,
    ),
    output: merge_string(
      cli_string(matches, crawl_output_option),
      config.output,
    ),
    limit: merge_int(cli_int(matches, crawl_limit_option), config.limit),
    depth: merge_int(cli_int(matches, crawl_depth_option), config.depth),
    formats: merge_string_array(
      match cli_string(matches, crawl_format_option) {
        Some(value) => Some(split_csv(value))
        None => None
      },
      config.formats,
    ),
  }
}

///|
fn CrawlStartBody::from_options(
  options : CrawlStartOptionsInput,
) -> CrawlStartBody raise {
  required_body_source(options.url, options.html)
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
async fn crawl_get_options(matches : @argparse.Matches) -> CrawlGetOptionsInput {
  let config = load_config(matches)
  {
    account_id: merged_account_id(matches, config),
    api_token: merged_api_token(matches, config),
    id: required_value(
      "id",
      merge_string(cli_string(matches, crawl_id_option), config.id),
    ),
    output: merge_string(
      cli_string(matches, crawl_output_option),
      config.output,
    ),
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
