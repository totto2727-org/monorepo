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
test "panic_GitHubRepository FromJson - invalid owner boundary is rejected" {
  try! ((
    @json.from_json(@json.parse("\"-owner/repository\"")) : GitHubRepository)
  |> ignore)
}

///|
test "panic_GitHubRepositoryName FromJson - overlong value is rejected" {
  let repository_name = "r".repeat(101)
  try! ((@json.from_json(repository_name.to_json()) : GitHubRepositoryName)
  |> ignore)
}

///|
test "Target FromJson and ToJson - preserves Path value" {
  let target : Target = @json.from_json(@json.parse("\".agents/skills\""))
  inspect(target.path().to_string(), content=".agents/skills")
  let decoded : Target = @json.from_json(target.to_json())
  inspect(decoded == target, content="true")
}

///|
test "panic_RelativeSourcePath FromJson - traversal is rejected" {
  try! ((@json.from_json(@json.parse("\"../marketplace\"")) : RelativeSourcePath)
  |> ignore)
}

///|
test "panic_CommitId FromJson - invalid length is rejected" {
  try! ((@json.from_json(@json.parse("\"0123456789abcdef\"")) : CommitId)
  |> ignore)
}
