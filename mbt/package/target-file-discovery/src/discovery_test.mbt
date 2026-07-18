///|
async fn write_target_file(dir : String, file_name : String) -> String {
  @fs.mkdir(dir, recursive=true) catch {
    _ => ()
  }
  let path = @path.Path::join(dir, file_name).to_string()
  @fs.write_file(path, "{}", create_mode=CreateOrTruncate)
  path
}

///|
async fn write_gitignore(dir : String, content : String) -> Unit {
  @fs.mkdir(dir, recursive=true) catch {
    _ => ()
  }
  @fs.write_file(
    @path.Path::join(dir, ".gitignore").to_string(),
    content,
    create_mode=CreateOrTruncate,
  )
}

///|
async test "find_home_target_file finds direct home file" {
  let root = @fs.tmpdir(prefix="target-file-discovery-home-")
  let home_dir = @path.Path::join(root, "home").to_string()
  let target = write_target_file(home_dir, "target.lock")
  inspect(find_home_target_file(home_dir, "target.lock"), content=target)
  @fs.rmdir(root, recursive=true)
}

///|
test "skipped: find_home_target_file failure message matches original JS" {
  // TODO: port once direct Failure assertion helper is available.
  // Original JS expects: Could not find home-level file: target.lock
}

///|
async test "find_parent_target_file finds target in start directory" {
  let root = @fs.tmpdir(prefix="target-file-discovery-parent-start-")
  let start_dir = (root
  |> @path.Path::join("packages")
  |> @path.Path::join("pkg-a")).to_string()
  let target = write_target_file(start_dir, "target.lock")
  inspect(
    find_parent_target_file("target.lock", root, start_dir),
    content=target,
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "find_parent_target_file finds nearest ancestor within boundary" {
  let root = @fs.tmpdir(prefix="target-file-discovery-parent-")
  let _root_target = write_target_file(root, "target.lock")
  let package_dir = (root
  |> @path.Path::join("packages")
  |> @path.Path::join("pkg-a")).to_string()
  let package_target = write_target_file(package_dir, "target.lock")
  let start_dir = (package_dir
  |> @path.Path::join("src")
  |> @path.Path::join("feature")).to_string()
  @fs.mkdir(start_dir, recursive=true)
  inspect(
    find_parent_target_file("target.lock", root, start_dir),
    content=package_target,
  )
  @fs.rmdir(root, recursive=true)
}

///|
test "skipped: find_parent_target_file missing ancestor failure message matches original JS" {
  // TODO: port once direct Failure assertion helper is available.
  // Original JS expects: Could not find ancestor file: target.lock
}

///|
async test "find_parent_target_file accepts target at top boundary" {
  let root = @fs.tmpdir(prefix="target-file-discovery-parent-boundary-")
  let top_target = write_target_file(root, "target.lock")
  let start_dir = (root
  |> @path.Path::join("packages")
  |> @path.Path::join("pkg-a")).to_string()
  @fs.mkdir(start_dir, recursive=true)
  inspect(
    find_parent_target_file("target.lock", root, start_dir),
    content=top_target,
  )
  @fs.rmdir(root, recursive=true)
}

///|
test "skipped: find_parent_target_file does not search above top boundary failure" {
  // TODO: port once direct Failure assertion helper is available.
  // Original JS creates an outer target above topDir and expects ancestor lookup to fail.
}

///|
async test "collect_recursive_target_files collects start and descendants" {
  let root = @fs.tmpdir(prefix="target-file-discovery-recursive-all-")
  let root_target = write_target_file(root, "target.lock")
  let child_target = write_target_file(
    (root |> @path.Path::join("packages") |> @path.Path::join("pkg-a")).to_string(),
    "target.lock",
  )
  let grandchild_target = write_target_file(
    (root
    |> @path.Path::join("packages")
    |> @path.Path::join("pkg-a")
    |> @path.Path::join("examples")
    |> @path.Path::join("demo")).to_string(),
    "target.lock",
  )
  let files = collect_recursive_target_files(root, "target.lock")
  assert_true(files.contains(root_target))
  assert_true(files.contains(child_target))
  assert_true(files.contains(grandchild_target))
  @fs.rmdir(root, recursive=true)
}

///|
async test "collect_recursive_target_files uses only gitignore rules for skip decisions" {
  let root = @fs.tmpdir(prefix="target-file-discovery-recursive-agents-")
  let root_target = write_target_file(root, "target.lock")
  let dot_agents_target = write_target_file(
    (root
    |> @path.Path::join(".agents")
    |> @path.Path::join(".cache")
    |> @path.Path::join("repo")).to_string(),
    "target.lock",
  )
  let files = collect_recursive_target_files(root, "target.lock")
  assert_true(files.contains(root_target))
  assert_true(files.contains(dot_agents_target))
  @fs.rmdir(root, recursive=true)
}

///|
async test "collect_recursive_target_files honors literal gitignore directory rules" {
  let root = @fs.tmpdir(prefix="target-file-discovery-recursive-")
  let root_target = write_target_file(root, "target.lock")
  write_gitignore(root, "ignored-packages/\ntarget.lock\n")
  let ignored_target = write_target_file(
    (root |> @path.Path::join("ignored-packages") |> @path.Path::join("pkg-a")).to_string(),
    "target.lock",
  )
  let visible_target = write_target_file(
    (root |> @path.Path::join("packages") |> @path.Path::join("pkg-a")).to_string(),
    "target.lock",
  )
  let files = collect_recursive_target_files(root, "target.lock")
  assert_true(files.contains(root_target))
  assert_true(files.contains(visible_target))
  assert_false(files.contains(ignored_target))
  @fs.rmdir(root, recursive=true)
}

///|
async test "collect_recursive_target_files trims anchored gitignore directory patterns" {
  let root = @fs.tmpdir(prefix="target-file-discovery-recursive-anchored-")
  let root_target = write_target_file(root, "target.lock")
  write_gitignore(root, "/ignored-packages/\n")
  let ignored_target = write_target_file(
    (root |> @path.Path::join("ignored-packages") |> @path.Path::join("pkg-a")).to_string(),
    "target.lock",
  )
  let visible_target = write_target_file(
    (root |> @path.Path::join("packages") |> @path.Path::join("pkg-a")).to_string(),
    "target.lock",
  )
  let files = collect_recursive_target_files(root, "target.lock")
  assert_true(files.contains(root_target))
  assert_true(files.contains(visible_target))
  assert_false(files.contains(ignored_target))
  @fs.rmdir(root, recursive=true)
}

///|
async test "collect_recursive_target_files ignores blank and comment gitignore lines" {
  let root = @fs.tmpdir(prefix="target-file-discovery-recursive-comments-")
  write_gitignore(root, "\n# ignored-packages/\nvisible-ignored/\n")
  let commented_target = write_target_file(
    (root |> @path.Path::join("ignored-packages") |> @path.Path::join("pkg-a")).to_string(),
    "target.lock",
  )
  let ignored_target = write_target_file(
    (root |> @path.Path::join("visible-ignored") |> @path.Path::join("pkg-a")).to_string(),
    "target.lock",
  )
  let files = collect_recursive_target_files(root, "target.lock")
  assert_true(files.contains(commented_target))
  assert_false(files.contains(ignored_target))
  @fs.rmdir(root, recursive=true)
}

///|
async test "collect_recursive_target_files supports simple star directory patterns" {
  let root = @fs.tmpdir(prefix="target-file-discovery-recursive-star-")
  write_gitignore(root, "ignored-*/\n")
  let ignored_target = write_target_file(
    (root |> @path.Path::join("ignored-alpha") |> @path.Path::join("pkg-a")).to_string(),
    "target.lock",
  )
  let visible_target = write_target_file(
    (root |> @path.Path::join("packages") |> @path.Path::join("pkg-a")).to_string(),
    "target.lock",
  )
  let files = collect_recursive_target_files(root, "target.lock")
  assert_true(files.contains(visible_target))
  assert_false(files.contains(ignored_target))
  @fs.rmdir(root, recursive=true)
}

///|
async test "collect_recursive_target_files inherits parent gitignore rules for grandchildren" {
  let root = @fs.tmpdir(prefix="target-file-discovery-recursive-inherit-")
  let root_target = write_target_file(root, "target.lock")
  let package_dir = (root
  |> @path.Path::join("packages")
  |> @path.Path::join("pkg-a")).to_string()
  write_gitignore(package_dir, "examples/ignored-demo/\n")
  let package_target = write_target_file(package_dir, "target.lock")
  let visible_demo_target = write_target_file(
    (package_dir
    |> @path.Path::join("examples")
    |> @path.Path::join("visible-demo")).to_string(),
    "target.lock",
  )
  let ignored_demo_target = write_target_file(
    (package_dir
    |> @path.Path::join("examples")
    |> @path.Path::join("ignored-demo")).to_string(),
    "target.lock",
  )
  let files = collect_recursive_target_files(root, "target.lock")
  assert_true(files.contains(root_target))
  assert_true(files.contains(package_target))
  assert_true(files.contains(visible_demo_target))
  assert_false(files.contains(ignored_demo_target))
  @fs.rmdir(root, recursive=true)
}

///|
async test "collect_recursive_target_files includes target files ignored by local gitignore" {
  let root = @fs.tmpdir(prefix="target-file-discovery-recursive-target-ignore-")
  write_gitignore(root, "target.lock")
  let ignored_root_target = write_target_file(root, "target.lock")
  let child_target = write_target_file(
    (root |> @path.Path::join("packages") |> @path.Path::join("pkg-a")).to_string(),
    "target.lock",
  )
  let files = collect_recursive_target_files(root, "target.lock")
  assert_true(files.contains(ignored_root_target))
  assert_true(files.contains(child_target))
  @fs.rmdir(root, recursive=true)
}
