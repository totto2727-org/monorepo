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
struct DevMarketplaceSyncOptions {
  kind : MarketplaceKind
}

///|
fn dev_marketplace_sync_options(
  matches : @argparse.Matches,
) -> DevMarketplaceSyncOptions raise {
  let kind = match matches.values.get(base_kind_arg) {
    Some([value, ..]) => marketplace_kind_from_string(value)
    _ => raise Failure::Failure("base kind is required")
  }
  { kind, }
}

///|
async fn run_dev_marketplace_sync(matches : @argparse.Matches) -> Unit {
  let options = dev_marketplace_sync_options(matches)
  let kind = options.kind
  let info = detect_marketplace(cwd()).unwrap_or_else(() => {
    raise Failure::Failure("No supported marketplace found")
  })
  guard same_marketplace_kind(info.kind, kind) else {
    raise Failure::Failure(
      "base marketplace \{marketplace_kind_to_string(kind)} not found",
    )
  }
  let text = @fs.read_file(info.path).text()
  for target_kind in marketplace_kinds() {
    if !same_marketplace_kind(target_kind, kind) {
      let path = "\{cwd()}/\{marketplace_path(target_kind)}"
      @fs.mkdir(dirname(path), recursive=true)
      @fs.write_file(path, text, create_mode=CreateOrTruncate)
      println("Wrote \{path}")
    }
  }
}
