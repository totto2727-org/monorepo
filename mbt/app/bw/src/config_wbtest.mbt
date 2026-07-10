///|
test "parse_config_object reads snake_case config keys" {
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
    #|  "formats": ["html", "markdown"]
    #|}
  let parsed = @json.parse(raw)
  let config = match parsed {
    Object(object) => parse_config_object(object)
    _ => fail("expected object")
  }
  assert_eq(config.account_id, Some("acct"))
  assert_eq(config.api_token, Some("token"))
  assert_eq(config.url, Some("https://example.com"))
  assert_eq(config.wait_until, Some("networkidle"))
  assert_eq(config.output, Some("out.png"))
  assert_eq(config.full_page, Some(true))
  assert_eq(config.width, Some(1024))
  assert_eq(config.height, Some(768))
  assert_eq(config.formats, Some(["html", "markdown"]))
}

///|
test "merge helpers prefer cli over config over default" {
  assert_eq(merge_string(Some("cli"), Some("config")), Some("cli"))
  assert_eq(merge_string(None, Some("config")), Some("config"))
  assert_eq(merge_bool(true, Some(false), false), true)
  assert_eq(merge_bool(false, Some(true), false), true)
  assert_eq(merge_bool(false, None, false), false)
}
