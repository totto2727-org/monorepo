///|
pub(all) struct OpenCodeAgentOptions {
  server_options : @sdk.ServerOptions
  command : String
  extra_env : Map[String, String]
  request_timeout_ms : Int
}

///|
pub fn OpenCodeAgentOptions::OpenCodeAgentOptions(
  server_options? : @sdk.ServerOptions = @sdk.ServerOptions(),
  command? : String = "opencode",
  extra_env? : Map[String, String] = Map([]),
  request_timeout_ms? : Int = 180000,
) -> OpenCodeAgentOptions {
  OpenCodeAgentOptions::{
    server_options,
    command,
    extra_env,
    request_timeout_ms,
  }
}

///|
/// Failures produced while validating OpenCode session and message responses.
pub(all) suberror OpenCodeAdapterError {
  InvalidSessionResponse
  InvalidMessageResponse
  MessageFailed(String)
  SessionClosed
} derive(Debug)

///|
priv struct OpenCodeAgentSession {
  server : @sdk.Server
  client : @moonllm.Client
  session_id : String
  workspace_root : @path.Path
  mutex : @async.Mutex
  mut closed : Bool
}

///|
fn session_path() -> String {
  "/session"
}

///|
fn message_path(session_id : String) -> String {
  "/session/\{session_id}/message"
}

///|
fn session_body(context : @core.CodingAgentOpenContext) -> Json {
  // SessionCreateData documents title as an official body field:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/v2/gen/types.gen.ts#L9469-L9489
  // The workspace is represented in text instead of the optional directory
  // query because no URL encoder is available at this boundary.
  Json::object({
    "title": "moon-agent-graph \{context.run_id.to_string()} workspace \{context.workspace.root.to_string()}".to_json(),
  })
}

///|
fn context_file_paths(
  workspace_root : @path.Path,
  context_files : Array[@path.Path],
) -> String {
  context_files
  .iter()
  .map(path => if path.is_absolute() { path } else { workspace_root.join(path) })
  .map(path => path.to_string())
  .join("\n")
}

///|
fn message_body(
  workspace_root : @path.Path,
  request : @core.CodingAgentRequest,
) -> Json {
  // SessionPromptData accepts text parts:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/v2/gen/types.gen.ts#L9790-L9815
  // Context paths are explicitly described rather than represented as
  // unattached file URLs.
  let context_paths = context_file_paths(workspace_root, request.context_files)
  let text = if context_paths.is_empty() {
    request.instruction
  } else {
    "\{request.instruction}\n\nContext file paths supplied by the caller (not attached):\n\{context_paths}"
  }
  Json::object({
    "parts": Json::array([
      Json::object({ "type": "text".to_json(), "text": text.to_json() }),
    ]),
  })
}

///|
fn decode_session_id(response : Json) -> String raise {
  guard response is Json::Object(fields) else {
    raise OpenCodeAdapterError::InvalidSessionResponse
  }
  match fields.get("id") {
    Some(Json::String(id)) if !id.is_empty() => id
    _ => raise OpenCodeAdapterError::InvalidSessionResponse
  }
}

///|
fn decode_response(
  session_id : String,
  response : Json,
) -> @core.CodingAgentResponse raise {
  guard response is Json::Object(fields) else {
    raise OpenCodeAdapterError::InvalidMessageResponse
  }
  guard fields.get("info") is Some(Json::Object(info)) else {
    raise OpenCodeAdapterError::InvalidMessageResponse
  }
  match info.get("error") {
    None | Some(Json::Null) => ()
    Some(error) => raise OpenCodeAdapterError::MessageFailed(error.stringify())
  }
  let texts : Array[String] = []
  match fields.get("parts") {
    Some(Json::Array(parts)) =>
      for part in parts {
        match part {
          Json::Object(part_fields) =>
            match (part_fields.get("type"), part_fields.get("text")) {
              (Some(Json::String("text")), Some(Json::String(text))) =>
                texts.push(text)
              _ => ()
            }
          _ => ()
        }
      }
    _ => ()
  }
  @core.CodingAgentResponse::{
    status: @core.Succeeded,
    summary: if texts.is_empty() {
      None
    } else {
      Some(texts.join(""))
    },
    continuation_id: Some(session_id),
    changed_files: [],
    artifacts: [],
    raw_output: Some(response),
  }
}

///|
fn merged_environment(
  options : OpenCodeAgentOptions,
  context : @core.CodingAgentOpenContext,
) -> Map[String, String] {
  let environment : Map[String, String] = Map([])
  for key, value in options.extra_env {
    environment[key] = value
  }
  // Run context is caller-owned, so it overrides adapter defaults.
  for key, value in context.environment {
    environment[key] = value
  }
  environment
}

///|
async fn open_session(
  context : @core.CodingAgentOpenContext,
  options : OpenCodeAgentOptions,
) -> &@core.CodingAgentSession {
  let server = @sdk.create_opencode_server(
    context.task_group,
    options=options.server_options,
    command=options.command,
    extra_env=merged_environment(options, context),
  )
  try {
    let client = server
      .moonllm_config()
      .timeout_ms(options.request_timeout_ms)
      .build()
    let session_id = client.post_json(session_path(), session_body(context))
      |> decode_session_id
    let session = OpenCodeAgentSession::{
      server,
      client,
      session_id,
      workspace_root: context.workspace.root,
      mutex: @async.Mutex::Mutex(),
      closed: false,
    }
    (session : &@core.CodingAgentSession)
  } catch {
    error => {
      @async.protect_from_cancel(async fn() { server.close() })
      if @async.is_being_cancelled() {
        @async.pause()
      }
      raise error
    }
  }
}

///|
impl @core.CodingAgentSession for OpenCodeAgentSession with fn id(self) {
  Some(@core.SessionId::parse(self.session_id) catch { _ => return None })
}

///|
impl @core.CodingAgentSession for OpenCodeAgentSession with fn execute(
  self,
  request,
) {
  self.mutex.acquire()
  defer self.mutex.release()
  guard !self.closed else { raise OpenCodeAdapterError::SessionClosed }
  let response = self.client.post_json(
    message_path(self.session_id),
    message_body(self.workspace_root, request),
  ) catch {
    error => {
      if @async.is_being_cancelled() {
        @async.pause()
      }
      raise error
    }
  }
  decode_response(self.session_id, response)
}

///|
impl @core.CodingAgentSession for OpenCodeAgentSession with fn close(self) {
  self.mutex.acquire()
  defer self.mutex.release()
  guard !self.closed else { return }
  self.server.close()
  self.closed = true
}

///|
/// Create a coding agent backed by one OpenCode server and session per opened session.
pub fn opencode_agent(
  id : @core.CodingAgentId,
  options : OpenCodeAgentOptions,
) -> @core.CodingAgent {
  @core.CodingAgent::{
    id,
    open: async fn(context) { open_session(context, options) },
  }
}
