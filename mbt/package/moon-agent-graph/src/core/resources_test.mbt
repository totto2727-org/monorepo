///|
struct ScopeFakeSession {
  id : SessionId
  label : String
  closed : Array[String]
}

///|
impl CodingAgentSession for ScopeFakeSession with fn id(self) {
  Some(self.id)
}

///|
impl CodingAgentSession for ScopeFakeSession with fn execute(self, _request) {
  @async.pause()
  CodingAgentResponse::{
    status: Succeeded,
    summary: Some(self.label),
    continuation_id: None,
    changed_files: [],
    artifacts: [],
    raw_output: None,
  }
}

///|
impl CodingAgentSession for ScopeFakeSession with fn close(self) {
  @async.pause()
  self.closed.push(self.label)
}

///|
async test "RuntimeResourceStore acquire_agent_session 1 - reuses run resources and closes node resources by owner" {
  let store = RuntimeResourceStore::RuntimeResourceStore()
  let opened : Array[String] = []
  let closed : Array[String] = []
  let run_key = ResourceKey::parse("run-agent")
  let node_key = ResourceKey::parse("node-agent")
  let first_node = NodeId::parse("first")
  let second_node = NodeId::parse("second")
  let run_session = store.acquire_agent_session(run_key, Run, async fn() {
    @async.pause()
    opened.push("run")
    let session = ScopeFakeSession::{
      id: SessionId::parse("run-session"),
      label: "run",
      closed,
    }
    (session : &CodingAgentSession)
  })
  let reused_run_session = store.acquire_agent_session(run_key, Run, async fn() {
    @async.pause()
    opened.push("unexpected")
    let session = ScopeFakeSession::{
      id: SessionId::parse("unexpected-session"),
      label: "unexpected",
      closed,
    }
    (session : &CodingAgentSession)
  })
  let first_node_session = store.acquire_agent_session(
    node_key,
    Node,
    async fn() {
      @async.pause()
      opened.push("node-first")
      let session = ScopeFakeSession::{
        id: SessionId::parse("node-first-session"),
        label: "node-first",
        closed,
      }
      (session : &CodingAgentSession)
    },
    owner=first_node,
  )
  let second_node_session = store.acquire_agent_session(
    node_key,
    Node,
    async fn() {
      @async.pause()
      opened.push("node-second")
      let session = ScopeFakeSession::{
        id: SessionId::parse("node-second-session"),
        label: "node-second",
        closed,
      }
      (session : &CodingAgentSession)
    },
    owner=second_node,
  )
  debug_inspect(
    [
      run_session.id(),
      reused_run_session.id(),
      first_node_session.id(),
      second_node_session.id(),
    ],
    content="[\n  Some(SessionId(\"run-session\")),\n  Some(SessionId(\"run-session\")),\n  Some(SessionId(\"node-first-session\")),\n  Some(SessionId(\"node-second-session\")),\n]",
  )
  inspect(opened.join(","), content="run,node-first,node-second")
  store.release_node(first_node)
  inspect(closed.join(","), content="node-first")
  store.release_node(first_node)
  store.close_all()
  inspect(closed.join(","), content="node-first,node-second,run")
  store.close_all()
  inspect(closed.join(","), content="node-first,node-second,run")
}
