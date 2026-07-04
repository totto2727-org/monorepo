///|
struct WorktreeEntry {
  path : String
  branch : String?
  is_main : Bool
}

///|
struct RepoWorktrees {
  repo_path : String
  slug : String
  entries : Array[WorktreeEntry]
}

///|
struct PrInfo {
  state : String
  number : String?
}

///|
fn format_pr(pr : PrInfo) -> String {
  match pr.state {
    "main" => "main"
    "none" => "none"
    state =>
      match pr.number {
        Some(number) => "#\{number} \{state}"
        None => state
      }
  }
}

///|
fn parse_github_remote(url : String) -> String? {
  let cleaned = if url.has_suffix(".git") {
    url[:url.length() - 4].to_owned()
  } else {
    url
  }
  if cleaned.has_prefix("https://github.com/") {
    Some(cleaned["https://github.com/".length():].to_owned())
  } else if cleaned.has_prefix("git@github.com:") {
    Some(cleaned["git@github.com:".length():].to_owned())
  } else {
    None
  }
}

///|
fn parse_worktree_list(output : String) -> Array[WorktreeEntry] {
  let entries : Array[WorktreeEntry] = []
  for block in output.split("\n\n") {
    let block_text = block.to_owned()
    let mut path : String? = None
    let mut branch : String? = None
    for line in lines(block_text) {
      match value_after_prefix(line, "worktree ") {
        Some(value) => path = Some(value)
        None => ()
      }
      match value_after_prefix(line, "branch refs/heads/") {
        Some(value) => branch = Some(value)
        None => ()
      }
    }
    match path {
      Some(path_value) =>
        entries.push({
          path: path_value,
          branch,
          is_main: entries.length() == 0,
        })
      None => ()
    }
  }
  entries
}

///|
async fn has_git_marker(path : String) -> Bool {
  @fs.exists(path)
}

///|
async fn discover_repos(base_dir : String) -> Array[String] {
  let repos : Array[String] = []
  if has_git_marker("\{base_dir}/.git") {
    repos.push(base_dir)
  }
  let child_names = @fs.readdir(
    base_dir,
    include_hidden=false,
    include_special=false,
    sort=true,
  )
  for name in child_names {
    let path = "\{base_dir}/\{name}"
    if has_git_marker("\{path}/.git") {
      repos.push(path)
    }
  }
  repos
}

///|
async fn fetch_repo_worktrees(repo : String) -> RepoWorktrees? {
  let top = collect_or_empty("git", ["-C", repo, "rev-parse", "--show-toplevel"])
  if top == "" {
    return None
  }
  let remote = collect_or_empty("git", [
    "-C", top, "config", "--get", "remote.origin.url",
  ])
  let slug = match parse_github_remote(remote) {
    Some(value) => value
    None => return None
  }
  let output = collect_or_empty("git", [
    "-C", top, "worktree", "list", "--porcelain",
  ])
  Some({ repo_path: top, slug, entries: parse_worktree_list(output) })
}

///|
async fn pr_info(slug : String, branch : String, is_main : Bool) -> PrInfo {
  if is_main {
    return { state: "main", number: None }
  }
  let open_json = collect_or_empty("gh", [
    "pr", "list", "--repo", slug, "--head", branch, "--state", "open", "--json",
    "number,state",
  ])
  if open_json != "" && open_json != "[]" {
    return { state: "open", number: parse_pr_number(open_json) }
  }
  let json = collect_or_empty("gh", [
    "pr", "list", "--repo", slug, "--head", branch, "--state", "all", "--json", "number,state",
  ])
  if json == "" {
    return { state: "unknown", number: None }
  }
  if json == "[]" {
    return { state: "none", number: None }
  }
  let state = if json.contains("\"MERGED\"") {
    "merged"
  } else if json.contains("\"OPEN\"") {
    "open"
  } else if json.contains("\"CLOSED\"") {
    "closed"
  } else {
    "none"
  }
  { state, number: parse_pr_number(json) }
}

///|
fn parse_pr_number(json : String) -> String? {
  let mut number : String? = None
  match json.find("\"number\":") {
    Some(start) => {
      let tail = json[start + "\"number\":".length():]
      let digits : Array[String] = []
      for ch in tail.iter() {
        if ch >= '0' && ch <= '9' {
          digits.push(ch.to_string())
        } else {
          break
        }
      }
      if digits.length() > 0 {
        number = Some(digits.join(""))
      }
    }
    None => ()
  }
  number
}

///|
async fn git_status(path : String) -> String {
  let dirty = collect_or_empty("git", ["-C", path, "status", "--porcelain"])
  if dirty != "" {
    return "dirty"
  }
  let upstream = collect_or_empty("git", [
    "-C", path, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}",
  ])
  if upstream == "" {
    return "committed"
  }
  let ahead = collect_or_empty("git", [
    "-C", path, "rev-list", "--count", "@{u}..HEAD",
  ])
  if ahead == "0" {
    "pushed"
  } else {
    "committed"
  }
}
