///|
test "cli_int rejects a provided non-integer value" {
  let values : Map[String, Array[String]] = { "width": ["not-an-int"] }
  let context : @admiral.Context = { flags: Map([]), values, subcommand: None }
  let mut raised = false
  try cli_int(context, screenshot_width_option) |> ignore catch {
    _ => raised = true
  }
  inspect(raised, content="true")
}
