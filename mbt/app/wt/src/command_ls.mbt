///|
let ls_dir_option = "dir"

///|
fn ls_command_def(
  run : async (@admiral.Context) -> Unit,
) -> @admiral.CommandDef {
  @admiral.command(
    name="ls",
    description="List git worktrees with PR status",
    positionals=[
      @admiral.positional(
        ls_dir_option,
        description="Base directory",
        required=false,
      ),
    ],
    run=Some(run),
  )
}

///|
struct LsOptions {
  dir : String
}

///|
fn ls_options(matches : @admiral.Context) -> LsOptions {
  let dir = match matches.values.get(ls_dir_option) {
    Some([value, ..]) => value
    _ => "."
  }
  { dir, }
}

///|
async fn run_ls(matches : @admiral.Context) -> Unit {
  let options = ls_options(matches)
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
