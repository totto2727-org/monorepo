///|
async fn main {
  @async.with_task_group() <| group => {
    let server = @opencode.create_opencode_server(group)
    try {
      let client = server.moonllm_config().build()
      let health = client.get_json("/global/health")
      println(@debug.to_string(health))
    } catch {
      err => {
        server.close()
        raise err
      }
    }
    server.close()
  }
}
