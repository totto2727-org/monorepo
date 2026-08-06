///|
fn expect_identity_json_rejection(
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
test "GitHubRepository FromJson and ToJson - canonicalizes route" {
  let repository : GitHubRepository = @json.from_json(
    @json.parse("\"OpenAI/Codex\""),
  )
  inspect(repository.route(), content="openai/codex")
  let decoded : GitHubRepository = @json.from_json(repository.to_json())
  inspect(decoded == repository, content="true")
}

///|
test "identity FromJson - rejects invalid boundary values" {
  expect_identity_json_rejection(
    fn() -> Unit raise {
      (@json.from_json(@json.parse("\"-owner/repository\"")) : GitHubRepository)
      |> ignore
    },
    "invalid GitHub owner boundary",
  )
  let repository_name = "r".repeat(101)
  expect_identity_json_rejection(
    fn() -> Unit raise {
      (@json.from_json(repository_name.to_json()) : GitHubRepositoryName)
      |> ignore
    },
    "overlong GitHub repository name",
  )
  expect_identity_json_rejection(
    fn() -> Unit raise {
      (@json.from_json(@json.parse("\"../marketplace\"")) : RelativeSourcePath)
      |> ignore
    },
    "relative source path traversal",
  )
  expect_identity_json_rejection(
    fn() -> Unit raise {
      (@json.from_json(@json.parse("\"0123456789abcdef\"")) : CommitId)
      |> ignore
    },
    "invalid commit length",
  )
}

///|
test "Target FromJson and ToJson - preserves Path value" {
  let target : Target = @json.from_json(@json.parse("\".agents/skills\""))
  inspect(target.path().to_string(), content=".agents/skills")
  let decoded : Target = @json.from_json(target.to_json())
  inspect(decoded == target, content="true")
}
