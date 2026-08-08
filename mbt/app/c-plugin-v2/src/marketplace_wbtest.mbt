///|
test "Marketplace FromJson - normalizes Claude Cursor and Codex plugin sources in declaration order" {
  let claude_text =
    #|{"name":"totto2727","description":"totto2727's plugins","owner":{"name":"totto2727","url":"https://github.com/totto2727","email":"owner@example.com"},"plugins":[{"name":"totto2727","source":"./plugins/totto2727"},{"name":"totto2727-coding","source":"./plugins/totto2727-coding"},{"name":"external-search","source":"./plugins/external-search"}]}
  let cursor_text =
    #|{"name":"totto2727","plugins":[{"name":"totto2727","source":"./plugins/totto2727"},{"name":"totto2727-coding","source":"./plugins/totto2727-coding"},{"name":"external-search","source":"./plugins/external-search"}]}
  let codex_text =
    #|{"name":"totto2727","plugins":[{"category":"Productivity","name":"totto2727","policy":{"authentication":"ON_INSTALL","installation":"INSTALLED_BY_DEFAULT"},"source":{"path":"./plugins/totto2727","source":"local"}},{"category":"Productivity","name":"totto2727-coding","policy":{"authentication":"ON_INSTALL","installation":"INSTALLED_BY_DEFAULT"},"source":{"path":"./plugins/totto2727-coding","source":"local"}},{"category":"Productivity","name":"external-search","policy":{"authentication":"ON_INSTALL","installation":"INSTALLED_BY_DEFAULT"},"source":{"path":"./plugins/external-search","source":"local"}}]}
  let marketplaces = [
    Marketplace::from_json(MarketplaceKind::claude(), @json.parse(claude_text)),
    Marketplace::from_json(MarketplaceKind::cursor(), @json.parse(cursor_text)),
    Marketplace::from_json(MarketplaceKind::codex(), @json.parse(codex_text)),
  ]
  debug_inspect(
    marketplaces.map(marketplace => {
      marketplace.plugins
      .map(plugin => "\{plugin.name.value}:\{plugin.path.path.to_string()}")
      .iter()
      .to_array()
    }),
    content=(
      #|[
      #|  [
      #|    "totto2727:plugins/totto2727",
      #|    "totto2727-coding:plugins/totto2727-coding",
      #|    "external-search:plugins/external-search",
      #|  ],
      #|  [
      #|    "totto2727:plugins/totto2727",
      #|    "totto2727-coding:plugins/totto2727-coding",
      #|    "external-search:plugins/external-search",
      #|  ],
      #|  [
      #|    "totto2727:plugins/totto2727",
      #|    "totto2727-coding:plugins/totto2727-coding",
      #|    "external-search:plugins/external-search",
      #|  ],
      #|]
    ),
  )
}

///|
test "Marketplace FromJson - malformed required field preserves JSON path" {
  let text =
    #|{"name":"test","plugins":[{"source":"./plugins/first"}]}
  try
    Marketplace::from_json(MarketplaceKind::claude(), @json.parse(text))
    |> ignore
  catch {
    @json.JsonDecodeError::JsonDecodeError((path, _)) =>
      inspect(path.to_string(), content="/plugins/0/name")
    _ => fail("expected JsonDecodeError")
  }
}

///|
test "Marketplace FromJson - relative plugin path rejects parent traversal" {
  let text =
    #|{"name":"test","plugins":[{"name":"first","source":"../outside"}]}
  try
    Marketplace::from_json(MarketplaceKind::cursor(), @json.parse(text))
    |> ignore
  catch {
    @json.JsonDecodeError::JsonDecodeError((path, _)) =>
      inspect(path.to_string(), content="/plugins/0/source")
    _ => fail("expected JsonDecodeError")
  }
}

///|
test "Marketplace FromJson - duplicate normalized plugin identity is rejected" {
  let text =
    #|{"name":"test","plugins":[{"name":"same","source":"plugins/first"},{"name":"same","source":"plugins/second"}]}
  try
    Marketplace::from_json(MarketplaceKind::claude(), @json.parse(text))
    |> ignore
  catch {
    @json.JsonDecodeError::JsonDecodeError((path, message)) => {
      inspect(path.to_string(), content="/plugins")
      inspect(message, content="marketplace plugin names must be unique")
    }
    _ => fail("expected JsonDecodeError")
  }
}

///|
test "Marketplace FromJson - Claude rejects Codex object source at source path" {
  let text =
    #|{"name":"test","plugins":[{"name":"first","source":{"source":"local","path":"plugins/first"}}]}
  try
    Marketplace::from_json(MarketplaceKind::claude(), @json.parse(text))
    |> ignore
  catch {
    @json.JsonDecodeError::JsonDecodeError((path, _)) =>
      inspect(path.to_string(), content="/plugins/0/source")
    _ => fail("expected JsonDecodeError")
  }
}

///|
test "Marketplace FromJson - Codex rejects string source at source path" {
  let text =
    #|{"name":"test","plugins":[{"name":"first","source":"plugins/first"}]}
  try
    Marketplace::from_json(MarketplaceKind::codex(), @json.parse(text))
    |> ignore
  catch {
    @json.JsonDecodeError::JsonDecodeError((path, _)) =>
      inspect(path.to_string(), content="/plugins/0/source")
    _ => fail("expected JsonDecodeError")
  }
}

///|
test "Marketplace FromJson - Codex rejects missing source discriminator" {
  let text =
    #|{"name":"test","plugins":[{"name":"first","source":{"path":"plugins/first"}}]}
  try
    Marketplace::from_json(MarketplaceKind::codex(), @json.parse(text))
    |> ignore
  catch {
    @json.JsonDecodeError::JsonDecodeError((path, _)) =>
      inspect(path.to_string(), content="/plugins/0/source/source")
    _ => fail("expected JsonDecodeError")
  }
}

///|
test "Marketplace FromJson - Codex rejects unsupported source discriminator" {
  let text =
    #|{"name":"test","plugins":[{"name":"first","source":{"source":"remote","path":"plugins/first"}}]}
  try
    Marketplace::from_json(MarketplaceKind::codex(), @json.parse(text))
    |> ignore
  catch {
    @json.JsonDecodeError::JsonDecodeError((path, _)) =>
      inspect(path.to_string(), content="/plugins/0/source/source")
    _ => fail("expected JsonDecodeError")
  }
}
