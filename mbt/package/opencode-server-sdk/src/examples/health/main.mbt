///|
async fn main {
  @async.with_task_group() <| group => {
    let server = @opencode.create_opencode_server(group)
    println(server.url())
    server.close()
  }
}
