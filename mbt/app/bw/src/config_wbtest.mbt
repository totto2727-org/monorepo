///|
test "parse_config_object - converts typed values to Admiral environment values" {
  let raw =
    #|{
    #|  "account_id": "acct",
    #|  "api_token": "token",
    #|  "url": "https://example.com",
    #|  "wait_until": "networkidle",
    #|  "output": "out.png",
    #|  "full_page": true,
    #|  "width": 1024,
    #|  "height": 768,
    #|  "format": "markdown",
    #|  "formats": ["html", "markdown"]
    #|}
  let parsed = @json.parse(raw)
  let config = match parsed {
    Object(object) => parse_config_object(object)
    _ => fail("expected object")
  }
  assert_eq(config.get(account_id_config_env), Some("acct"))
  assert_eq(config.get(api_token_config_env), Some("token"))
  assert_eq(config.get(url_config_env), Some("https://example.com"))
  assert_eq(config.get(wait_until_config_env), Some("networkidle"))
  assert_eq(config.get(output_config_env), Some("out.png"))
  assert_eq(config.get(full_page_config_env), Some("true"))
  assert_eq(config.get(width_config_env), Some("1024"))
  assert_eq(config.get(height_config_env), Some("768"))
  assert_eq(config.get(format_config_env), Some("markdown"))
  assert_eq(config.get(formats_config_env), Some("html,markdown"))
}

///|
async test "load_config - reads an explicitly selected config file" {
  let config = load_config(process_args=[
    "bw", "markdown", "--config", "src/testdata/config.json",
  ])
  assert_eq(config.get(url_config_env), Some("https://example.com"))
  assert_eq(config.get(full_page_config_env), Some("false"))
}

///|
async test "load_config - missing default file produces empty values" {
  let config = load_config(process_args=["bw", "markdown"])
  assert_eq(config.length(), 0)
}

///|
async test "load_config - missing explicit file raises" {
  let mut raised = false
  (load_config(process_args=[
    "bw", "markdown", "--config", "src/testdata/missing.json",
  ])
  |> ignore) catch {
    @admiral.ConfigLoadFailure(message) =>
      raised = message.contains("does not exist")
  }
  inspect(raised, content="true")
}
