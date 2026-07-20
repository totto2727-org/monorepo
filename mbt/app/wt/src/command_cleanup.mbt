///|
let cleanup_dir_option = "dir"

///|
let cleanup_dry_run_option = "dry-run"

///|
fn cleanup_command_def() -> @admiral.CommandDef {
  @admiral.command(
    name="cleanup",
    description="Remove worktrees with merged or no PR",
    positionals=[
      @admiral.positional(
        cleanup_dir_option,
        description="Base directory",
        required=false,
      ),
    ],
    options=[
      @admiral.bool(
        cleanup_dry_run_option,
        short='n',
        description="Print removals without changing files",
      ),
    ],
  )
}

///|
struct CleanupOptions {
  dir : String
  dry_run : Bool
}

///|
fn cleanup_options(matches : @argparse.Matches) -> CleanupOptions {
  let dir = match matches.values.get(cleanup_dir_option) {
    Some([value, ..]) => value
    _ => "."
  }
  { dir, dry_run: matches.flags.contains(cleanup_dry_run_option) }
}

///|
fn removal_reason(pr : PrInfo, git : String) -> String? {
  if git != "pushed" {
    return None
  }
  if pr.state == "merged" {
    return Some("merged (pushed)")
  }
  if pr.state == "closed" {
    return Some("closed (pushed)")
  }
  if pr.state == "none" {
    return Some("no PR (pushed)")
  }
  None
}

///|
async fn run_cleanup(matches : @argparse.Matches) -> Unit {
  let options = cleanup_options(matches)
  let dir = options.dir
  let dry_run = options.dry_run
  let base = if dir == "." { @env.current_dir().unwrap_or(".") } else { dir }
  let mut removed = 0
  let mut skipped = 0
  match fetch_repo_worktrees(base) {
    Some(result) => {
      let status_array = collect_worktree_statuses(
        result.entries.filter(entry => !entry.is_main),
        entry => fetch_worktree_status(result.slug, entry),
      )
      for status in status_array {
        match removal_reason(status.pr, status.git) {
          Some(reason) => {
            let prefix = if dry_run {
              "[dry-run] Would remove"
            } else {
              "Removing"
            }
            println(
              "\{prefix}: \{status.entry.path} (\{status.branch}, \{reason})",
            )
            if !dry_run {
              run_checked("git", [
                "-C",
                result.repo_path,
                "worktree",
                "remove",
                status.entry.path,
              ])
              run_checked("git", [
                "-C",
                result.repo_path,
                "branch",
                "-d",
                status.branch,
              ])
            }
            removed = removed + 1
          }
          None => skipped = skipped + 1
        }
      }
      if !dry_run {
        run_checked("git", ["-C", result.repo_path, "worktree", "prune"])
      }
    }
    None => {
      println("No git repositories found.")
      return
    }
  }
  let suffix = if dry_run { " (dry-run)" } else { "" }
  println("Done: \{removed} removed, \{skipped} skipped\{suffix}")
}
