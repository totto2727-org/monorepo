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
struct WorktreeStatus {
  entry : WorktreeEntry
  branch : String
  pr : PrInfo
  git : String
}

///|
fn WorktreeStatus::WorktreeStatus(
  entry~ : WorktreeEntry,
  branch~ : String,
  pr~ : PrInfo,
  git~ : String,
) -> WorktreeStatus {
  WorktreeStatus::{ entry, branch, pr, git }
}

///|
async fn collect_worktree_statuses(
  entry_array : Array[WorktreeEntry],
  fetch : async (WorktreeEntry) -> WorktreeStatus?,
) -> Array[WorktreeStatus] {
  let task_array = entry_array.map(entry => () => fetch(entry))
  @async.all(task_array).filter_map(status => status)
}

///|
async fn fetch_worktree_status(
  slug : String,
  entry : WorktreeEntry,
) -> WorktreeStatus? {
  match entry.branch {
    Some(branch) => {
      let (pr, git) = @async.with_task_group(group => {
        let pr_task = group.spawn(() => pr_info(slug, branch, entry.is_main))
        let git_task = group.spawn(() => git_status(entry.path))
        (pr_task.wait(), git_task.wait())
      })
      Some(WorktreeStatus(entry~, branch~, pr~, git~))
    }
    None => None
  }
}

///|
fn format_pr(pr : PrInfo) -> String {
  match pr.state {
    "main" => "main"
    "none" => "none"
    "merged" =>
      match pr.number {
        Some(number) => "MERGED(#\{number})"
        None => "MERGED(#?)"
      }
    "open" =>
      match pr.number {
        Some(number) => "OPEN(#\{number})"
        None => "OPEN(#?)"
      }
    "closed" =>
      match pr.number {
        Some(number) => "CLOSED(#\{number})"
        None => "CLOSED(#?)"
      }
    state => state
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
fn parse_worktree_list(
  output : String,
  repo_path : String,
) -> Array[WorktreeEntry] {
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
          is_main: path_value == repo_path,
        })
      None => ()
    }
  }
  entries
}

///|
async fn fetch_repo_worktrees(repo : String) -> RepoWorktrees? {
  let top = collect_or_empty("git", ["-C", repo, "rev-parse", "--show-toplevel"])
  if top == "" {
    return None
  }
  let (remote, output) = @async.with_task_group(group => {
    let remote_task = group.spawn(() => {
      collect_or_empty("git", [
        "-C", top, "config", "--get", "remote.origin.url",
      ])
    })
    let worktree_task = group.spawn(() => {
      collect_or_empty("git", ["-C", top, "worktree", "list", "--porcelain"])
    })
    (remote_task.wait(), worktree_task.wait())
  })
  let slug = match parse_github_remote(remote) {
    Some(value) => value
    None => return None
  }
  Some({ repo_path: top, slug, entries: parse_worktree_list(output, top) })
}

///|
async fn pr_info(slug : String, branch : String, is_main : Bool) -> PrInfo {
  if is_main {
    return { state: "main", number: None }
  }
  let (open_json, json) = @async.with_task_group(group => {
    let open_task = group.spawn(() => {
      collect_or_empty("gh", [
        "pr", "list", "--repo", slug, "--head", branch, "--state", "open", "--json",
        "number,state",
      ])
    })
    let all_task = group.spawn(() => {
      collect_or_empty("gh", [
        "pr", "list", "--repo", slug, "--head", branch, "--state", "all", "--json",
        "number,state",
      ])
    })
    (open_task.wait(), all_task.wait())
  })
  if open_json != "" && open_json != "[]" {
    return { state: "open", number: parse_pr_number(open_json) }
  }
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
  let (dirty, upstream) = @async.with_task_group(group => {
    let dirty_task = group.spawn(() => {
      collect_or_empty("git", ["-C", path, "status", "--porcelain"])
    })
    let upstream_task = group.spawn(() => {
      collect_or_empty("git", [
        "-C", path, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}",
      ])
    })
    (dirty_task.wait(), upstream_task.wait())
  })
  if dirty != "" {
    return "dirty"
  }
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
