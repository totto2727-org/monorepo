///|
enum ToolAccess {
  NoTools
  WebFetchOnly
}

///|
struct PermissionRule {
  permission : String
  pattern : String
  action : String
}

///|
impl ToJson for PermissionRule with fn to_json(self) -> Json {
  Json::object({
    "permission": self.permission.to_json(),
    "pattern": self.pattern.to_json(),
    "action": self.action.to_json(),
  })
}

///|
fn ToolAccess::permission_rules(self : ToolAccess) -> Array[PermissionRule] {
  // OpenCode evaluates the last matching permission rule. Deny everything
  // first, then allow only webfetch for the URL summarizer:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/opencode/src/permission/index.ts#L28-L37
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/opencode/src/tool/webfetch.ts#L13-L26
  let deny_all : PermissionRule = {
    permission: "*",
    pattern: "*",
    action: "deny",
  }
  match self {
    NoTools => [deny_all]
    WebFetchOnly => [
      deny_all,
      { permission: "webfetch", pattern: "*", action: "allow" },
    ]
  }
}

///|
struct SessionCreateBody {
  title : String
  tool_access : ToolAccess
}

///|
impl ToJson for SessionCreateBody with fn to_json(self) -> Json {
  // OpenCode session creation accepts title and a permission ruleset:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/v2/gen/types.gen.ts#L9469-L9507
  Json::object({
    "title": self.title.to_json(),
    "permission": self.tool_access.permission_rules().to_json(),
  })
}

///|
extend SessionCreateBody with ToJson::{to_json}

///|
struct PromptBody {
  system : String
  text : String
}

///|
impl ToJson for PromptBody with fn to_json(self) -> Json {
  // OpenCode's prompt endpoint accepts a system prompt, output format, and
  // typed input parts:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/v2/gen/types.gen.ts#L9790-L9837
  Json::object({
    "format": Json::object({ "type": "text".to_json() }),
    "system": self.system.to_json(),
    "parts": Json::array([
      Json::object({
        "type": "text".to_json(),
        "text": self.text.to_json(),
      }),
    ]),
  })
}

///|
extend PromptBody with ToJson::{to_json}

///|
struct PromptRequest {
  title : String
  tool_access : ToolAccess
  system : String
  text : String
}

///|
fn decode_session_id(response : Json) -> String raise {
  // OpenCode returns the created Session directly:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/v2/gen/types.gen.ts#L9469-L9507
  guard response is Json::Object(fields) else {
    fail("OpenCode returned a non-object session response")
  }
  match fields.get("id") {
    Some(Json::String(id)) => id
    _ => fail("OpenCode session response is missing a string id")
  }
}

///|
fn decode_assistant_text(response : Json) -> String raise {
  // OpenCode returns a message info object and typed output parts:
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/v2/gen/types.gen.ts#L9790-L9837
  // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/v2/gen/types.gen.ts#L378-L393
  guard response is Json::Object(fields) else {
    fail("OpenCode returned a non-object prompt response")
  }
  guard fields.get("info") is Some(Json::Object(info)) else {
    fail("OpenCode prompt response is missing message info")
  }
  match info.get("error") {
    None | Some(Json::Null) => ()
    Some(error) =>
      fail("OpenCode assistant failed: \{@debug.to_string(error)}")
  }
  guard fields.get("parts") is Some(Json::Array(parts)) else {
    fail("OpenCode prompt response is missing message parts")
  }
  let texts : Array[String] = []
  for part in parts {
    match part {
      Json::Object(part_fields) =>
        match (part_fields.get("type"), part_fields.get("text")) {
          (Some(Json::String(kind)), Some(Json::String(text))) =>
            if kind == "text" {
              texts.push(text)
            }
          _ => ()
        }
      _ => ()
    }
  }
  guard !texts.is_empty() else {
    fail("OpenCode assistant returned no text")
  }
  texts.join("")
}

///|
async fn run_prompt(request : PromptRequest) -> String raise {
  @async.with_task_group() <| group => {
    let server = @opencode.create_opencode_server(group)
    let result = try {
      let client = server
        .moonllm_config()
        .timeout_ms(180000)
        .build()
      // These paths mirror the OpenCode SDK session create and prompt calls:
      // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/v2/gen/sdk.gen.ts#L3410-L3457
      // https://github.com/anomalyco/opencode/blob/66495a2a22cd0a57efcc4f721e65532f0987b4e8/packages/sdk/js/src/v2/gen/sdk.gen.ts#L3742-L3794
      let session = client.post_json(
        "/session",
        SessionCreateBody::{
          title: request.title,
          tool_access: request.tool_access,
        }.to_json(),
      )
      let session_id = decode_session_id(session)
      client.post_json(
        "/session/\{session_id}/message",
        PromptBody::{ system: request.system, text: request.text }.to_json(),
      )
      |> decode_assistant_text
    } catch {
      err => {
        server.close()
        raise err
      }
    }
    server.close()
    result
  }
}
