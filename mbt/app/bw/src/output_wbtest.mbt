///|
async test "write_snapshot writes both output files" {
  let root = @fs.tmpdir(prefix="bw-snapshot-output-")
  let output = "\{root}/capture"
  let screenshot = @base64.std_decode2bytes("cG5n")
  write_snapshot(output, "<html></html>", screenshot)
  assert_true(@fs.exists("\{output}/capture.html"))
  assert_true(@fs.exists("\{output}/capture.png"))
  inspect(
    @fs.read_file("\{output}/capture.html").text(),
    content="<html></html>",
  )
  @fs.rmdir(root, recursive=true)
}
