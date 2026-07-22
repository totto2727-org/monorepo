///|
test "parse_config_object - converts scalar properties and ignores arrays" {
  let raw =
    #|{
    #|  "CLOUDFLARE_ACCOUNT_ID": "acct",
    #|  "BW_URL": "https://example.com",
    #|  "BW_FULL_PAGE": true,
    #|  "BW_WIDTH": 1024,
    #|  "BW_CRAWL_FORMATS": ["html", "markdown"],
    #|  "CUSTOM_OBJECT": { "enabled": true },
    #|  "CUSTOM_NULL": null
    #|}
  let parsed = @json.parse(raw)
  let config = match parsed {
    Object(object) => parse_config_object(object)
    _ => fail("expected object")
  }
  assert_eq(config.get(account_id_config_env), Some("acct"))
  assert_eq(config.get(url_config_env), Some("https://example.com"))
  assert_eq(config.get(full_page_config_env), Some("true"))
  assert_eq(config.get(width_config_env), Some("1024"))
  assert_eq(config.get(formats_config_env), None)
  assert_eq(config.get("CUSTOM_OBJECT"), Some("{\"enabled\":true}"))
  assert_eq(config.get("CUSTOM_NULL"), Some("null"))
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
