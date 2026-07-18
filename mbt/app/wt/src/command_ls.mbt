///|
let ls_dir_option = "dir"

///|
fn ls_command_def() -> @admiral.CommandDef {
  @admiral.command(name="ls", description="List git worktrees with PR status", positionals=[
    @admiral.positional(
      ls_dir_option,
      description="Base directory",
      required=false,
    ),
  ])
}

///|
struct LsOptions {
  dir : String
}

///|
fn ls_options(matches : @argparse.Matches) -> LsOptions {
  let dir = match matches.values.get(ls_dir_option) {
    Some([value, ..]) => value
    _ => "."
  }
  { dir, }
}

///|
async fn run_ls(matches : @argparse.Matches) -> Unit {
  let options = ls_options(matches)
  let dir = options.dir
  let base = if dir == "." { @env.current_dir().unwrap_or(".") } else { dir }
  let repos = discover_repos(base)
  if repos.length() == 0 {
    println("No git repositories found.")
    return
  }
  println("NAME\tBRANCH\tPR\tGIT\tPATH")
  let seen : Array[String] = []
  for repo in repos {
    match fetch_repo_worktrees(repo) {
      Some(result) =>
        for entry in result.entries {
          if seen.contains(entry.path) {
            continue
          }
          seen.push(entry.path)
          match entry.branch {
            Some(branch) => {
              let pr = pr_info(result.slug, branch, entry.is_main)
              let git = git_status(entry.path)
              println(
                "\{basename(entry.path)}\t\{branch}\t\{format_pr(pr)}\t\{git}\t\{entry.path}",
              )
            }
            None => ()
          }
        }
      None => ()
    }
  }
}
