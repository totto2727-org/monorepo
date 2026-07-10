///|
async fn write_text_or_stdout(output : @path.Path?, text : String) -> Unit {
  match output {
    Some(path) => {
      let file_path = path.to_string()
      @fs.write_file(file_path, text, create_mode=CreateOrTruncate)
      println("Written to \{file_path}")
    }
    None => println(text)
  }
}

///|
async fn write_binary(
  path : @path.Path,
  data : &@io.Data,
  label : String,
) -> Unit {
  let file_path = path.to_string()
  @fs.write_file(file_path, data, create_mode=CreateOrTruncate)
  println("\{label} saved to \{file_path}")
}

///|
async fn write_snapshot(
  output : @path.Path,
  content : String,
  screenshot : Bytes,
) -> Unit {
  let dir = output.snapshot_dir()
  let name = output.snapshot_base_name()
  let html_path = dir.join("\{name}.html").to_string()
  let screenshot_path = dir.join("\{name}.png").to_string()
  let dir_path = dir.to_string()
  @fs.mkdir(dir_path, recursive=true)
  @fs.write_file(html_path, content, create_mode=CreateOrTruncate)
  @fs.write_file(screenshot_path, screenshot, create_mode=CreateOrTruncate)
  println("Snapshot saved to \{dir_path}/")
}
