///|
fn expect_lock_json_rejection(
  action : () -> Unit raise,
  detail : String,
) -> Unit raise {
  try action() catch {
    _ => ()
  } noraise {
    _ => fail("expected JSON rejection: \{detail}")
  }
}

///|
let canonical_lock_json =
  #|{
  #|  "version": "2",
  #|  "targets": [
  #|    ".agents/skills",
  #|    ".cursor/skills"
  #|  ],
  #|  "repositories": [
  #|    {
  #|      "type": "github",
  #|      "repository": "openai/codex",
  #|      "marketplaceKind": "codex",
  #|      "commit": "0123456789abcdef0123456789abcdef01234567",
  #|      "plugins": [
  #|        {
  #|          "name": "c-plugin",
  #|          "path": "plugins/c-plugin",
  #|          "enabledSkills": [
  #|            "install",
  #|            "sync"
  #|          ]
  #|        }
  #|      ]
  #|    },
  #|    {
  #|      "type": "local",
  #|      "path": "vendor/plugin",
  #|      "marketplaceKind": "claude",
  #|      "plugins": []
  #|    }
  #|  ]
  #|}

///|
test "Lock FromJson and ToJson - canonical round trip preserves order" {
  let lock : Lock = @json.parse(canonical_lock_json) |> @json.from_json
  inspect(lock.to_pretty_json(), content=canonical_lock_json + "\n")
  let decoded : Lock = @json.from_json(lock.to_json())
  inspect(decoded == lock, content="true")
  inspect(decoded.targets[0].path().to_string(), content=".agents/skills")
  match decoded.repositories[0] {
    GitHub(repository) =>
      inspect(
        repository.plugins[0].enabled_skills[0].value(),
        content="install",
      )
    Local(_) => fail("first repository must remain GitHub")
  }
}

///|
test "Lock FromJson - nested failure preserves JSON path" {
  let invalid_text = "{\"version\":\"2\",\"targets\":[],\"repositories\":[{\"type\":\"github\",\"repository\":\"openai/codex\",\"marketplaceKind\":\"codex\",\"commit\":\"0123456789abcdef0123456789abcdef01234567\",\"plugins\":[{\"name\":\"c-plugin\",\"path\":\"plugins/c-plugin\",\"enabledSkills\":[1]}]}]}"
  let invalid = @json.parse(invalid_text)
  try {
    let _ : Lock = @json.from_json(invalid)
    fail("expected nested decode failure")
  } catch {
    @json.JsonDecodeError::JsonDecodeError((path, _)) =>
      inspect(
        path.to_string(),
        content="/repositories/0/plugins/0/enabledSkills/0",
      )
    _ => fail("expected JsonDecodeError")
  }
}

///|
test "Lock FromJson - unsupported version preserves input" {
  let text = "{\"version\":\"3\",\"targets\":[],\"repositories\":[]}"
  let json = @json.parse(text)
  try {
    let _ : Lock = @json.from_json(json)
    fail("expected unsupported version failure")
  } catch {
    @json.JsonDecodeError::JsonDecodeError((path, message)) => {
      inspect(path.to_string(), content="/version")
      inspect(message, content="unsupported lock version: 3")
    }
    _ => fail("expected JsonDecodeError")
  }
  inspect(json.stringify(), content=text)
}

///|
test "LockRepository FromJson - dispatches each top-level type" {
  let github_text = "{\"type\":\"github\",\"repository\":\"openai/codex\",\"marketplaceKind\":\"codex\",\"commit\":\"0123456789abcdef0123456789abcdef01234567\",\"plugins\":[]}"
  let local_text = "{\"type\":\"local\",\"path\":\"vendor/plugin\",\"marketplaceKind\":\"claude\",\"plugins\":[]}"
  let github : LockRepository = @json.from_json(@json.parse(github_text))
  let local_repository : LockRepository = @json.from_json(
    @json.parse(local_text),
  )
  match github {
    GitHub(_) => inspect(true, content="true")
    Local(_) => fail("expected GitHub repository")
  }
  match local_repository {
    Local(_) => inspect(true, content="true")
    GitHub(_) => fail("expected local repository")
  }
}

///|
test "lock FromJson - rejects strict schema failures" {
  expect_lock_json_rejection(
    fn() -> Unit raise {
      let text = "{\"version\":\"2\",\"targets\":[],\"repositories\":[{\"type\":\"gitlab\"}]}"
      (@json.from_json(@json.parse(text)) : Lock) |> ignore
    },
    "unknown repository type",
  )
  expect_lock_json_rejection(
    fn() -> Unit raise {
      let text = "{\"version\":\"2\",\"targets\":[],\"repositories\":[{\"type\":1}]}"
      (@json.from_json(@json.parse(text)) : Lock) |> ignore
    },
    "repository type with wrong JSON type",
  )
  expect_lock_json_rejection(
    fn() -> Unit raise {
      let text = "{\"version\":2,\"targets\":[],\"repositories\":[]}"
      (@json.from_json(@json.parse(text)) : Lock) |> ignore
    },
    "numeric lock version",
  )
  expect_lock_json_rejection(
    fn() -> Unit raise {
      let text = "{\"version\":\"2.5\",\"targets\":[],\"repositories\":[]}"
      (@json.from_json(@json.parse(text)) : Lock) |> ignore
    },
    "fractional lock version",
  )
  expect_lock_json_rejection(
    fn() -> Unit raise {
      let text = "{\"version\":\"2.0000000000000001\",\"targets\":[],\"repositories\":[]}"
      (@json.from_json(@json.parse(text)) : Lock) |> ignore
    },
    "precision-sensitive lock version",
  )
  expect_lock_json_rejection(
    fn() -> Unit raise {
      let text = "{\"type\":\"github\",\"repository\":\"openai/codex\",\"marketplaceKind\":\"codex\",\"plugins\":[]}"
      (@json.from_json(@json.parse(text)) : GitHubLockRepository) |> ignore
    },
    "missing GitHub commit",
  )
  expect_lock_json_rejection(
    fn() -> Unit raise {
      let text = "{\"type\":\"github\",\"repository\":\"openai/codex\",\"marketplaceKind\":\"codex\",\"commit\":null,\"plugins\":[]}"
      (@json.from_json(@json.parse(text)) : GitHubLockRepository) |> ignore
    },
    "null GitHub commit",
  )
  expect_lock_json_rejection(
    fn() -> Unit raise {
      (@json.from_json(@json.parse("\"unknown\"")) : MarketplaceKind) |> ignore
    },
    "unknown marketplace kind",
  )
  expect_lock_json_rejection(
    fn() -> Unit raise {
      let text =
        #|{"version":"2","targets":[],"repositories":[{"type":"github","repository":"OpenAI/Codex","marketplaceKind":"codex","commit":"0123456789abcdef0123456789abcdef01234567","plugins":[]},{"type":"github","repository":"openai/codex","marketplaceKind":"claude","commit":"fedcba9876543210fedcba9876543210fedcba98","plugins":[]}]}
      (@json.from_json(@json.parse(text)) : Lock) |> ignore
    },
    "duplicate repository identity",
  )
}
