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
