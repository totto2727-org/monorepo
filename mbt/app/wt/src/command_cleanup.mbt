///|
let cleanup_dir_option : @admiral.PositionDef[String] = @admiral.position_string(
  "dir",
  description="Base directory",
  required=false,
)

///|
let cleanup_dry_run_option : @admiral.OptionDef[Bool] = @admiral.bool(
  "dry-run",
  short='n',
  description="Print removals without changing files",
)

///|
fn cleanup_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="cleanup",
    description="Remove worktrees with merged or no PR",
    positionals=[cleanup_dir_option],
    options=[cleanup_dry_run_option],
    run=Some(run),
  )
}

///|
struct CleanupOptions {
  dir : String
  dry_run : Bool
}

///|
fn cleanup_options(context : @admiral.Context) -> CleanupOptions raise {
  let dir = match context.get_string(cleanup_dir_option) {
    Some(value) => value
    None => "."
  }
  { dir, dry_run: context.get_bool(cleanup_dry_run_option) }
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
async fn run_cleanup(context : @admiral.Context) -> Unit {
  let options = cleanup_options(context)
  let dir = options.dir
  let dry_run = options.dry_run
  let base = if dir == "." { @env.current_dir().unwrap_or(".") } else { dir }
  let (removed, skipped) = match fetch_repo_worktrees(base) {
    Some(result) => {
      let status_array = collect_worktree_statuses(
        result.entries.filter(entry => !entry.is_main),
        entry => fetch_worktree_status(result.slug, entry),
      )
      let count_array = @async.all(
        status_array.map(status => {
          () => {
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
                (1, 0)
              }
              None => (0, 1)
            }
          }
        }),
        max_concurrent=1,
      )
      if !dry_run {
        run_checked("git", ["-C", result.repo_path, "worktree", "prune"])
      }
      count_array
      .iter()
      .fold(init=(0, 0), fn(total, count) {
        (total.0 + count.0, total.1 + count.1)
      })
    }
    None => {
      println("No git repositories found.")
      return
    }
  }
  let suffix = if dry_run { " (dry-run)" } else { "" }
  println("Done: \{removed} removed, \{skipped} skipped\{suffix}")
}
