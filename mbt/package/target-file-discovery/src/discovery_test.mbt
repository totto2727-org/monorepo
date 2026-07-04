///|
fn test_join_path(base : String, name : String) -> String {
  if base == "" || base == "/" {
    "/\{name}"
  } else if base.has_suffix("/") {
    "\{base}\{name}"
  } else {
    "\{base}/\{name}"
  }
}

///|
async fn write_target_file(dir : String, file_name : String) -> String {
  @fs.mkdir(dir, recursive=true) catch {
    _ => ()
  }
  let path = test_join_path(dir, file_name)
  @fs.write_file(path, "{}", create_mode=CreateOrTruncate)
  path
}

///|
async fn write_gitignore(dir : String, content : String) -> Unit {
  @fs.mkdir(dir, recursive=true) catch {
    _ => ()
  }
  @fs.write_file(
    test_join_path(dir, ".gitignore"),
    content,
    create_mode=CreateOrTruncate,
  )
}

///|
async test "find_home_target_file finds direct home file" {
  let root = @fs.tmpdir(prefix="target-file-discovery-home-")
  let home_dir = test_join_path(root, "home")
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
  let start_dir = test_join_path(root, "packages/pkg-a")
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
  let package_dir = test_join_path(root, "packages/pkg-a")
  let package_target = write_target_file(package_dir, "target.lock")
  let start_dir = test_join_path(package_dir, "src/feature")
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
  let start_dir = test_join_path(root, "packages/pkg-a")
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
    test_join_path(root, "packages/pkg-a"),
    "target.lock",
  )
  let grandchild_target = write_target_file(
    test_join_path(root, "packages/pkg-a/examples/demo"),
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
    test_join_path(root, ".agents/.cache/repo"),
    "target.lock",
  )
  let files = collect_recursive_target_files(root, "target.lock")
  assert_true(files.contains(root_target))
  assert_true(files.contains(dot_agents_target))
  @fs.rmdir(root, recursive=true)
}

///|
async test "collect_recursive_target_files honors gitignore only for directories" {
  let root = @fs.tmpdir(prefix="target-file-discovery-recursive-")
  let root_target = write_target_file(root, "target.lock")
  write_gitignore(root, "ignored-packages/\ntarget.lock\n")
  let ignored_target = write_target_file(
    test_join_path(root, "ignored-packages/pkg-a"),
    "target.lock",
  )
  let visible_target = write_target_file(
    test_join_path(root, "packages/pkg-a"),
    "target.lock",
  )
  let files = collect_recursive_target_files(root, "target.lock")
  assert_true(files.contains(root_target))
  assert_true(files.contains(visible_target))
  assert_false(files.contains(ignored_target))
  @fs.rmdir(root, recursive=true)
}

///|
async test "collect_recursive_target_files honors anchored gitignore directory patterns" {
  let root = @fs.tmpdir(prefix="target-file-discovery-recursive-anchored-")
  let root_target = write_target_file(root, "target.lock")
  write_gitignore(root, "/ignored-packages/\n")
  let ignored_target = write_target_file(
    test_join_path(root, "ignored-packages/pkg-a"),
    "target.lock",
  )
  let visible_target = write_target_file(
    test_join_path(root, "packages/pkg-a"),
    "target.lock",
  )
  let files = collect_recursive_target_files(root, "target.lock")
  assert_true(files.contains(root_target))
  assert_true(files.contains(visible_target))
  assert_false(files.contains(ignored_target))
  @fs.rmdir(root, recursive=true)
}

///|
async test "collect_recursive_target_files inherits parent gitignore rules for grandchildren" {
  let root = @fs.tmpdir(prefix="target-file-discovery-recursive-inherit-")
  let root_target = write_target_file(root, "target.lock")
  let package_dir = test_join_path(root, "packages/pkg-a")
  write_gitignore(package_dir, "examples/ignored-demo/\n")
  let package_target = write_target_file(package_dir, "target.lock")
  let visible_demo_target = write_target_file(
    test_join_path(package_dir, "examples/visible-demo"),
    "target.lock",
  )
  let ignored_demo_target = write_target_file(
    test_join_path(package_dir, "examples/ignored-demo"),
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
    test_join_path(root, "packages/pkg-a"),
    "target.lock",
  )
  let files = collect_recursive_target_files(root, "target.lock")
  assert_true(files.contains(ignored_root_target))
  assert_true(files.contains(child_target))
  @fs.rmdir(root, recursive=true)
}
