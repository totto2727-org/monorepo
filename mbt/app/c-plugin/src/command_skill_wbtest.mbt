///|
test "skill_add_options - rejects a local path that escapes its root" {
  let context = @admiral.Context(values={ "local": ["./../outside"] })
  let outcome = try {
    skill_add_options(context) |> ignore
    "returned"
  } catch {
    _ => "raised"
  }
  inspect(outcome, content="raised")
}

///|
test "skill_add_options - rejects simultaneous repository and local sources" {
  let context = @admiral.Context(values={
    "repo": ["owner/repository"],
    "local": ["./marketplace"],
  })
  let outcome = try {
    skill_add_options(context) |> ignore
    "returned"
  } catch {
    _ => "raised"
  }
  inspect(outcome, content="raised")
}
