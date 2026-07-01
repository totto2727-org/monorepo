///|
let base_kind_arg = "base-kind"

///|
fn dev_marketplace_sync_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="sync",
    description="Regenerate marketplace manifests from a base kind",
    positionals=[
      @admiral.positional(base_kind_arg, description="claude, cursor, or codex"),
    ],
  )
}

///|
async fn run_dev_marketplace_sync(matches : @argparse.Matches) -> Unit {
  let kind = match matches.values.get(base_kind_arg) {
    Some([value, ..]) => value
    _ => fail("base kind is required")
  }
  let info = detect_marketplace(cwd()).unwrap_or_else(() => {
    fail("No supported marketplace found")
  })
  guard info.kind == kind else { fail("base marketplace \{kind} not found") }
  let text = @fs.read_file(info.path).text()
  for target_kind in ["claude", "cursor", "codex"] {
    if target_kind != kind {
      let path = "\{cwd()}/\{marketplace_path(target_kind)}"
      @fs.mkdir(dirname(path), recursive=true)
      @fs.write_file(path, text, create_mode=CreateOrTruncate)
      println("Wrote \{path}")
    }
  }
}
