///|
test "command without run falls back to help when no match exists" {
  let command_without_run = command(name="group")
  inspect(fallback_to_help_when_no_match(command_without_run), content="true")
}

///|
test "runnable command preserves normal execution" {
  let runnable = command(name="run", run=Some(fn(_ctx) { () }))
  inspect(fallback_to_help_when_no_match(runnable), content="false")
}
