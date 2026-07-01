///|
async fn collect(
  command : String,
  args : Array[String],
  cwd? : String,
) -> (Int, String, String) {
  let (code, stdout, stderr) = match cwd {
    Some(dir) => @process.collect_output(command, args, cwd=dir)
    None => @process.collect_output(command, args)
  }
  (code, stdout.text().trim().to_owned(), stderr.text().trim().to_owned())
}

///|
async fn collect_or_empty(
  command : String,
  args : Array[String],
  cwd? : String,
) -> String {
  let (code, stdout, _) = match cwd {
    Some(dir) => collect(command, args, cwd=dir)
    None => collect(command, args)
  }
  if code == 0 {
    stdout
  } else {
    ""
  }
}

///|
async fn run_checked(
  command : String,
  args : Array[String],
  cwd? : String,
) -> Unit {
  let (code, _, stderr) = match cwd {
    Some(dir) => collect(command, args, cwd=dir)
    None => collect(command, args)
  }
  guard code == 0 else { fail(stderr) }
}
