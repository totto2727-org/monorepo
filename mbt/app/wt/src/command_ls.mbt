///|
let ls_dir_option : @admiral.PositionDef[String] = @admiral.position_string(
  "dir",
  description="Base directory",
  required=false,
)

///|
fn ls_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="ls",
    description="List git worktrees with PR status",
    positionals=[ls_dir_option],
    run=Some(run),
  )
}

///|
struct LsOptions {
  dir : String
}

///|
fn ls_options(context : @admiral.Context) -> LsOptions {
  let dir = match context.get_string(ls_dir_option) {
    Some(value) => value
    None => "."
  }
  { dir, }
}

///|
async fn run_ls(context : @admiral.Context) -> Unit {
  let options = ls_options(context)
  let dir = options.dir
  let base = if dir == "." { @env.current_dir().unwrap_or(".") } else { dir }
  match fetch_repo_worktrees(base) {
    Some(result) => {
      println("NAME\tBRANCH\tPR\tGIT\tPATH")
      let status_array = collect_worktree_statuses(result.entries, entry => {
        fetch_worktree_status(result.slug, entry)
      })
      for status in status_array {
        println(
          "\{basename(status.entry.path)}\t\{status.branch}\t\{format_pr(status.pr)}\t\{status.git}\t\{status.entry.path}",
        )
      }
    }
    None => println("No git repositories found.")
  }
}
