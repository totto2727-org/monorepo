///|
async fn write_text_or_stdout(output : String?, text : String) -> Unit {
  match output {
    Some(path) => {
      @fs.write_file(path, text, create_mode=CreateOrTruncate)
      println("Written to \{path}")
    }
    None => println(text)
  }
}

///|
async fn write_binary(path : String, data : &@io.Data, label : String) -> Unit {
  @fs.write_file(path, data, create_mode=CreateOrTruncate)
  println("\{label} saved to \{path}")
}

///|
fn snapshot_base_name(output : String) -> String {
  let base = output.trim_end(chars="/").to_owned()
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
async fn write_snapshot(
  output : String,
  content : String,
  screenshot : Bytes,
) -> Unit {
  let dir = output.trim_end(chars="/").to_owned()
  let dir = if dir == "" { "snapshot" } else { dir }
  let name = snapshot_base_name(output)
  @fs.mkdir(dir, recursive=true)
  @async.all([
    () => {
      @fs.write_file(
        "\{dir}/\{name}.html",
        content,
        create_mode=CreateOrTruncate,
      )
    },
    () => {
      @fs.write_file(
        "\{dir}/\{name}.png",
        screenshot,
        create_mode=CreateOrTruncate,
      )
    },
  ])
  |> ignore
  println("Snapshot saved to \{dir}/")
}
