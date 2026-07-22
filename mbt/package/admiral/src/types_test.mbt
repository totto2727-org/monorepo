///|
test "OptionDef holds string option metadata" {
  let opt : @admiral.OptionDef[String] = @admiral.string(
    "output",
    short='o',
    description="Output path",
    required=true,
  )
  inspect(opt.name, content="output")
  inspect(opt.metadata.type_, content="StringOpt")
  inspect(opt.metadata.required, content="true")
}

///|
test "CommandDef holds subcommands" {
  let sub : @admiral.CommandDef = {
    name: "sub",
    description: "A subcommand",
    options: [],
    positionals: [],
    examples: [],
    subcommands: [],
    run: Some(fn(_ctx) { () }),
  }
  let cmd : @admiral.CommandDef = {
    name: "app",
    description: "An app",
    options: [],
    positionals: [],
    examples: [],
    subcommands: [sub],
    run: None,
  }
  inspect(cmd.subcommands.length(), content="1")
  inspect(cmd.subcommands[0].name, content="sub")
}
