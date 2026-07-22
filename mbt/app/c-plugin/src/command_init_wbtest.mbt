///|
test "init_options - reads the global flag" {
  let context : @admiral.Context = {
    flags: { "global": true },
    values: Map([]),
    subcommand: None,
  }
  inspect(init_options(context).global, content="true")
}

///|
async test "init_lock_file creates agents directory and empty lock file" {
  let root = @fs.tmpdir(prefix="c-plugin-init-test-")
  let lock_path = init_lock_file(root)
  inspect(lock_path, content=@path.Path::join(root, lock_file_name).to_string())
  inspect(@fs.read_file(lock_path).text(), content=empty_lock_text())
  inspect(
    @fs.readdir(@path.Path::join(root, ".agents").to_string()).length(),
    content="0",
  )
  @fs.rmdir(root, recursive=true)
}

///|
async test "init_lock_file does not overwrite existing lock file" {
  let root = @fs.tmpdir(prefix="c-plugin-init-existing-test-")
  let lock_path = @path.Path::join(root, lock_file_name).to_string()
  @test_support.write_text(
    lock_path, "{\"version\":1,\"repositories\":[],\"skillDirs\":[\"/keep\"]}\n",
  )
  try {
    ignore(init_lock_file(root))
    inspect("no error", content="error")
  } catch {
    _ => ()
  }
  inspect(
    @fs.read_file(lock_path).text(),
    content="{\"version\":1,\"repositories\":[],\"skillDirs\":[\"/keep\"]}\n",
  )
  @fs.rmdir(root, recursive=true)
}
