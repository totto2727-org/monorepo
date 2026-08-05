///|
async test "same integer getters accept option and position definitions" {
  let limit = int("limit", required=true)
  let value = position_int("value", required=true)
  let captured = Ref((0, 0))
  let app = CliApp::CliApp(name="test", commands=[
    CommandDef::CommandDef(
      name="number",
      options=[limit],
      positionals=[value],
      run=Some(ctx => {
        captured.val = (
          ctx.get_int_required(limit),
          ctx.get_int_required(value),
        )
      }),
    ),
  ])
  app.run(argv=Some(["number", "--limit", "7", "42"]))
  inspect(captured.val.0, content="7")
  inspect(captured.val.1, content="42")
}

///|
async test "scalar positions consume one value in declaration order" {
  let input = position_string("input", required=true)
  let output = position_string("output")
  let captured = Ref(("", ""))
  let app = CliApp::CliApp(name="test", commands=[
    CommandDef::CommandDef(
      name="copy",
      positionals=[input, output],
      run=Some(ctx => {
        captured.val = (
          ctx.get_string_required(input),
          ctx.get_string(output).unwrap_or("missing"),
        )
      }),
    ),
  ])
  app.run(argv=Some(["copy", "a.txt", "b.txt"]))
  inspect(captured.val.0, content="a.txt")
  inspect(captured.val.1, content="b.txt")
}

///|
async test "scalar positions reject an extra value" {
  let input = position_string("input", required=true)
  let output = position_string("output")
  let called = Ref(false)
  let app = CliApp::CliApp(name="test", commands=[
    CommandDef::CommandDef(
      name="copy",
      positionals=[input, output],
      run=Some(fn(_ctx) { called.val = true }),
    ),
  ])
  let mut raised = false
  app.run(argv=Some(["copy", "a.txt", "b.txt", "c.txt"])) catch {
    _ => raised = true
  }
  inspect(raised, content="true")
  inspect(called.val, content="false")
}

///|
async test "array position preserves values and reserves a trailing scalar" {
  let files = position_strings("files", required=true)
  let target = position_string("target", required=true)
  let captured : Ref[(ReadOnlyArray[String], String)] = Ref(([], ""))
  let app = CliApp::CliApp(name="test", commands=[
    CommandDef::CommandDef(
      name="pack",
      positionals=[files, target],
      run=Some(ctx => {
        captured.val = (
          ctx.get_strings_required(files).all,
          ctx.get_string_required(target),
        )
      }),
    ),
  ])
  app.run(argv=Some(["pack", "a.txt", "b.txt", "out.zip"]))
  inspect(captured.val.0.length(), content="2")
  inspect(captured.val.0[0], content="a.txt")
  inspect(captured.val.0[1], content="b.txt")
  inspect(captured.val.1, content="out.zip")
}
