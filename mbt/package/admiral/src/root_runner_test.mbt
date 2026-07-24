///|
async test "CliApp run - executes root callback" {
  let file = position_string("file", required=true)
  let lang = string("lang", required=true)
  let observed : Ref[String] = { val: "" }
  let app = cli(
    name="mdt",
    options=[lang],
    positionals=[file],
    run=Some(async fn(context) {
      @async.sleep(0)
      observed.val = context.get_string_required(file) +
        ":" +
        context.get_string_required(lang)
    }),
  )
  app.run(argv=Some(["README.md", "--lang", "ja"]), env=Map([]))
  inspect(observed.val, content="README.md:ja")
}
