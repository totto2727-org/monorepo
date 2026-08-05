///|
test "command without run falls back to help when no match exists" {
  let command_without_run = CommandDef::CommandDef(name="group")
  inspect(fallback_to_help_when_no_match(command_without_run), content="true")
}

///|
test "runnable command preserves normal execution" {
  let runnable = CommandDef::CommandDef(name="run", run=Some(fn(_ctx) { () }))
  inspect(fallback_to_help_when_no_match(runnable), content="false")
}
