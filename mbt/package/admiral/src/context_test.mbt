///|
test "get_bool returns flag value" {
  let verbose = bool("verbose")
  let missing = bool("missing")
  let flags : Map[String, Bool] = { "verbose": true }
  let ctx : Context = { flags, values: Map([]), subcommand: None }
  inspect(ctx.get_bool(verbose), content="true")
  inspect(ctx.get_bool(missing), content="false")
}

///|
test "get_string returns first value" {
  let name = string("name")
  let missing = string("missing")
  let values : Map[String, Array[String]] = { "name": ["alice"] }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  debug_inspect(ctx.get_string(name), content="Some(\"alice\")")
  debug_inspect(ctx.get_string(missing), content="None")
}

///|
test "get_string_required raises on missing" {
  let name = string("name", required=true)
  let ctx : Context = { flags: Map([]), values: Map([]), subcommand: None }
  let mut raised = false
  try ctx.get_string_required(name) |> ignore catch {
    _ => raised = true
  }
  inspect(raised, content="true")
}

///|
test "get_int parses integer value" {
  let count = int("count")
  let missing = int("missing")
  let values : Map[String, Array[String]] = { "count": ["42"] }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  debug_inspect(ctx.get_int(count), content="Some(42)")
  debug_inspect(ctx.get_int(missing), content="None")
}

///|
test "get_int returns None for non-integer" {
  let count = int("count")
  let values : Map[String, Array[String]] = { "count": ["abc"] }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  debug_inspect(ctx.get_int(count), content="None")
}

///|
test "get_int returns None for overflow" {
  let n = int("n")
  let values : Map[String, Array[String]] = { "n": ["99999999999999999999"] }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  debug_inspect(ctx.get_int(n), content="None")
}

///|
test "get_int parses negative" {
  let n = int("n")
  let values : Map[String, Array[String]] = { "n": ["-42"] }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  debug_inspect(ctx.get_int(n), content="Some(-42)")
}

///|
test "get_int_required raises on missing" {
  let port = int("port", required=true)
  let ctx : Context = { flags: Map([]), values: Map([]), subcommand: None }
  let mut raised = false
  try ctx.get_int_required(port) |> ignore catch {
    _ => raised = true
  }
  inspect(raised, content="true")
}

///|
test "get_int_required raises on non-integer" {
  let port = int("port", required=true)
  let values : Map[String, Array[String]] = { "port": ["abc"] }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  let mut raised = false
  try ctx.get_int_required(port) |> ignore catch {
    _ => raised = true
  }
  inspect(raised, content="true")
}

///|
test "get_int_required returns value" {
  let port = int("port", required=true)
  let values : Map[String, Array[String]] = { "port": ["8080"] }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  let result = ctx.get_int_required(port) catch { _ => -1 }
  inspect(result, content="8080")
}

///|
test "numeric getters parse supported string number types" {
  let int64_option = int64("int64")
  let uint_option = uint("uint")
  let uint64_option = uint64("uint64")
  let double_option = double("double")
  let values : Map[String, Array[String]] = {
    "int64": ["9223372036854775807"],
    "uint": ["4294967295"],
    "uint64": ["18446744073709551615"],
    "double": ["1.25"],
  }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  debug_inspect(
    ctx.get_int64(int64_option).map(fn(value) { value.to_string() }),
    content="Some(\"9223372036854775807\")",
  )
  debug_inspect(
    ctx.get_uint(uint_option).map(fn(value) { value.to_string() }),
    content="Some(\"4294967295\")",
  )
  debug_inspect(
    ctx.get_uint64(uint64_option).map(fn(value) { value.to_string() }),
    content="Some(\"18446744073709551615\")",
  )
  debug_inspect(ctx.get_double(double_option), content="Some(1.25)")
}

///|
test "numeric getters return None for invalid values" {
  let int64_option = int64("int64")
  let uint_option = uint("uint")
  let uint64_option = uint64("uint64")
  let double_option = double("double")
  let values : Map[String, Array[String]] = {
    "int64": ["invalid"],
    "uint": ["-1"],
    "uint64": ["invalid"],
    "double": ["invalid"],
  }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  debug_inspect(ctx.get_int64(int64_option), content="None")
  debug_inspect(ctx.get_uint(uint_option), content="None")
  debug_inspect(ctx.get_uint64(uint64_option), content="None")
  debug_inspect(ctx.get_double(double_option), content="None")
}

///|
test "required numeric getters return parsed values" {
  let int64_option = int64("int64", required=true)
  let uint_option = uint("uint", required=true)
  let uint64_option = uint64("uint64", required=true)
  let double_option = double("double", required=true)
  let values : Map[String, Array[String]] = {
    "int64": ["42"],
    "uint": ["42"],
    "uint64": ["42"],
    "double": ["1.25"],
  }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  inspect(ctx.get_int64_required(int64_option).to_string(), content="42")
  inspect(ctx.get_uint_required(uint_option).to_string(), content="42")
  inspect(ctx.get_uint64_required(uint64_option).to_string(), content="42")
  inspect(ctx.get_double_required(double_option), content="1.25")
}

///|
test "get_strings returns all values" {
  let files_option = strings("files")
  let values : Map[String, Array[String]] = { "files": ["a.txt", "b.txt"] }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  let files = ctx.get_strings_required(files_option) catch { _ => [] }
  inspect(files.length(), content="2")
  inspect(files[0], content="a.txt")
}

///|
test "string getters accept PositionDef" {
  let file = position_string("file", required=true)
  let values : Map[String, Array[String]] = { "file": ["a.txt"] }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  debug_inspect(ctx.get_string(file), content="Some(\"a.txt\")")
  inspect(ctx.get_string_required(file), content="a.txt")
}

///|
test "plural getters accept PositionDef" {
  let files = position_strings("files", required=true)
  let values : Map[String, Array[String]] = { "files": ["a.txt", "b.txt"] }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  let result = ctx.get_strings_required(files)
  inspect(result.length(), content="2")
}

///|
test "required getter raises for missing PositionDef" {
  let file = position_string("file", required=true)
  let ctx : Context = { flags: Map([]), values: Map([]), subcommand: None }
  let mut raised = false
  try ctx.get_string_required(file) |> ignore catch {
    _ => raised = true
  }
  inspect(raised, content="true")
}

///|
test "numeric array getters reject an invalid element" {
  let values : Map[String, Array[String]] = { "ids": ["1", "invalid", "3"] }
  let ctx : Context = { flags: Map([]), values, subcommand: None }
  debug_inspect(ctx.get_ints(ints("ids")), content="None")
  debug_inspect(ctx.get_ints(position_ints("ids")), content="None")
}

///|
test "get_subcommand returns nested context" {
  let port = string("port")
  let sub_ctx : Context = {
    flags: Map([]),
    values: { "port": ["8080"] },
    subcommand: None,
  }
  let ctx : Context = {
    flags: Map([]),
    values: Map([]),
    subcommand: Some(("serve", sub_ctx)),
  }
  match ctx.get_subcommand() {
    Some((name, sub)) => {
      inspect(name, content="serve")
      debug_inspect(sub.get_string(port), content="Some(\"8080\")")
    }
    None => fail("expected subcommand")
  }
}
