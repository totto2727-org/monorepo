///|
pub struct Path {
  value : String
} derive(Eq, Debug)

///|
pub fn Path::from_cli(value : String) -> Path {
  Path::{ value: expand_home(value, @env.get_env_var("HOME")) }
}

///|
pub fn Path::from_cli_with_home(value : String, home : String) -> Path {
  Path::{ value: expand_home(value, Some(home)) }
}

///|
pub fn Path::to_string(self : Path) -> String {
  self.value
}

///|
pub async fn Path::read_text(self : Path) -> String {
  @fs.read_file(self.value).text()
}

///|
pub fn Path::snapshot_dir(self : Path) -> Path {
  let dir = self.value.trim_end(chars="/").to_owned()
  Path::{ value: if dir == "" { "snapshot" } else { dir } }
}

///|
pub fn Path::snapshot_base_name(self : Path) -> String {
  let base = self.value.trim_end(chars="/").to_owned()
  if base == "" {
    "snapshot"
  } else {
    match base.rev_find("/") {
      Some(index) => base[index + 1:].to_owned()
      None => base
    }
  }
}

///|
pub fn Path::join(self : Path, name : String) -> Path {
  Path::{ value: "\{self.value}/\{name}" }
}

///|
fn expand_home(value : String, home : String?) -> String {
  match home {
    Some(home) =>
      if value == "~" {
        home
      } else if value.length() >= 2 && value[0:2] == "~/" {
        "\{home}\{value[1:]}"
      } else {
        value
      }
    None => value
  }
}

///|
test "Path::from_cli_with_home - expands exact tilde" {
  @test.assert_eq(
    Path::from_cli_with_home("~", "/Users/example").to_string(),
    "/Users/example",
  )
}

///|
test "Path::from_cli_with_home - expands leading tilde slash" {
  @test.assert_eq(
    Path::from_cli_with_home("~/page.html", "/Users/example").to_string(),
    "/Users/example/page.html",
  )
}

///|
test "Path::from_cli_with_home - leaves other tilde forms unchanged" {
  @test.assert_eq(
    Path::from_cli_with_home("~other/page.html", "/Users/example").to_string(),
    "~other/page.html",
  )
  @test.assert_eq(
    Path::from_cli_with_home("tmp/~/page.html", "/Users/example").to_string(),
    "tmp/~/page.html",
  )
}

///|
test "Path::from_cli_with_home - leaves relative and absolute paths unchanged" {
  @test.assert_eq(
    Path::from_cli_with_home("tmp/page.html", "/Users/example").to_string(),
    "tmp/page.html",
  )
  @test.assert_eq(
    Path::from_cli_with_home("/tmp/page.html", "/Users/example").to_string(),
    "/tmp/page.html",
  )
}

///|
test "expand_home - leaves paths unchanged when home is missing" {
  @test.assert_eq(expand_home("~", None), "~")
  @test.assert_eq(expand_home("~/page.html", None), "~/page.html")
}

///|
test "Path snapshot helpers - preserve directory output behavior" {
  let path = Path::from_cli_with_home("reports/page/", "/Users/example")
  @test.assert_eq(path.snapshot_dir().to_string(), "reports/page")
  @test.assert_eq(path.snapshot_base_name(), "page")
  @test.assert_eq(
    path.snapshot_dir().join("page.html").to_string(),
    "reports/page/page.html",
  )
}

///|
test "Path snapshot helpers - empty trimmed output uses snapshot" {
  let path = Path::from_cli_with_home("/", "/Users/example")
  @test.assert_eq(path.snapshot_dir().to_string(), "snapshot")
  @test.assert_eq(path.snapshot_base_name(), "snapshot")
}
