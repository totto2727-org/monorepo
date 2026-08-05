///|
pub struct FakeCodingAgentOpenCall {
  context : @core.CodingAgentOpenContext
}

///|
pub struct FakeCodingAgentRequestCall {
  session_id : @core.SessionId?
  request : @core.CodingAgentRequest
}

///|
pub struct FakeCodingAgentSession {
  id_value : @core.SessionId?
  response_value : @core.CodingAgentResponse
  execute_error : Error?
  requests_value : Array[FakeCodingAgentRequestCall]
  close_order_value : Array[@core.SessionId?]
  mut closed : Bool
}

///|
pub fn FakeCodingAgentSession::requests(
  self : FakeCodingAgentSession,
) -> ReadOnlyArray[FakeCodingAgentRequestCall] {
  ReadOnlyArray::from_array([..self.requests_value])
}

///|
pub fn FakeCodingAgentSession::is_closed(self : FakeCodingAgentSession) -> Bool {
  self.closed
}

///|
impl @core.CodingAgentSession for FakeCodingAgentSession with fn id(self) {
  self.id_value
}

///|
impl @core.CodingAgentSession for FakeCodingAgentSession with fn execute(
  self,
  request,
) {
  self.requests_value.push(FakeCodingAgentRequestCall::{
    session_id: self.id_value,
    request,
  })
  match self.execute_error {
    Some(error) => raise error
    None => self.response_value
  }
}

///|
impl @core.CodingAgentSession for FakeCodingAgentSession with fn close(self) {
  guard !self.closed else { return }
  self.closed = true
  self.close_order_value.push(self.id_value)
}

///|
pub struct FakeCodingAgent {
  value : @core.CodingAgent
  open_calls_value : Array[FakeCodingAgentOpenCall]
  request_calls_value : Array[FakeCodingAgentRequestCall]
  session_ids_value : Array[@core.SessionId?]
  close_order_value : Array[@core.SessionId?]
}

///|
/// Create a deterministic coding-agent fixture with optional open or execute failures.
pub fn fake_coding_agent(
  response : @core.CodingAgentResponse,
  session_id? : @core.SessionId,
  open_error? : Error,
  execute_error? : Error,
) -> FakeCodingAgent {
  let open_calls : Array[FakeCodingAgentOpenCall] = []
  let request_calls : Array[FakeCodingAgentRequestCall] = []
  let session_ids : Array[@core.SessionId?] = []
  let close_order : Array[@core.SessionId?] = []
  let value = @core.CodingAgent::CodingAgent(
    @core.CodingAgentId::parse("fake-coding-agent") catch {
      _ => abort("static fake agent ID must be valid")
    },
    async fn(context) {
      @async.pause()
      open_calls.push(FakeCodingAgentOpenCall::{ context, })
      match open_error {
        Some(error) => raise error
        None => ()
      }
      session_ids.push(session_id)
      let session = FakeCodingAgentSession::{
        id_value: session_id,
        response_value: response,
        execute_error,
        requests_value: request_calls,
        close_order_value: close_order,
        closed: false,
      }
      (session : &@core.CodingAgentSession)
    },
  )
  FakeCodingAgent::{
    value,
    open_calls_value: open_calls,
    request_calls_value: request_calls,
    session_ids_value: session_ids,
    close_order_value: close_order,
  }
}

///|
pub fn FakeCodingAgent::agent(self : FakeCodingAgent) -> @core.CodingAgent {
  self.value
}

///|
pub fn FakeCodingAgent::open_calls(
  self : FakeCodingAgent,
) -> ReadOnlyArray[FakeCodingAgentOpenCall] {
  ReadOnlyArray::from_array([..self.open_calls_value])
}

///|
pub fn FakeCodingAgent::request_calls(
  self : FakeCodingAgent,
) -> ReadOnlyArray[FakeCodingAgentRequestCall] {
  ReadOnlyArray::from_array([..self.request_calls_value])
}

///|
pub fn FakeCodingAgent::session_ids(
  self : FakeCodingAgent,
) -> ReadOnlyArray[@core.SessionId?] {
  ReadOnlyArray::from_array([..self.session_ids_value])
}

///|
pub fn FakeCodingAgent::close_order(
  self : FakeCodingAgent,
) -> ReadOnlyArray[@core.SessionId?] {
  ReadOnlyArray::from_array([..self.close_order_value])
}

///|
pub struct FakeMoonLlmInvoke {
  response_value : @llm.ChatResponse
  error_value : Error?
  requests_value : Array[@llm.ChatRequest]
}

///|
/// Create a deterministic MoonLLM invocation callback with an owned request history.
pub fn fake_moonllm_invoke(
  response : @llm.ChatResponse,
  error? : Error,
) -> FakeMoonLlmInvoke {
  FakeMoonLlmInvoke::{
    response_value: response,
    error_value: error,
    requests_value: [],
  }
}

///|
pub fn FakeMoonLlmInvoke::callback(
  self : FakeMoonLlmInvoke,
) -> async (@llm.ChatRequest) -> @llm.ChatResponse {
  async fn(request) {
    @async.pause()
    self.requests_value.push(request)
    match self.error_value {
      Some(error) => raise error
      None => self.response_value
    }
  }
}

///|
pub fn FakeMoonLlmInvoke::requests(
  self : FakeMoonLlmInvoke,
) -> ReadOnlyArray[@llm.ChatRequest] {
  ReadOnlyArray::from_array([..self.requests_value])
}
