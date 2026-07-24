///|
struct ModelSelection {
  provider_id : String
  model_id : String
}

///|
fn parse_model(raw : String) -> ModelSelection raise {
  guard raw.find("/") is Some(slash) && slash > 0 && slash < raw.length() - 1 else {
    fail("invalid model format: \{raw}")
  }
  { provider_id: raw[:slash].to_owned(), model_id: raw[slash + 1:].to_owned() }
}

///|
impl ToJson for ModelSelection with fn to_json(self) -> Json {
  Json::object({
    "providerID": self.provider_id.to_json(),
    "modelID": self.model_id.to_json(),
  })
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
struct SessionCreateBody {
  title : String
}

///|
impl ToJson for SessionCreateBody with fn to_json(self) -> Json {
  let deny_all : PermissionRule = {
    permission: "*",
    pattern: "*",
    action: "deny",
  }
  Json::object({
    "title": self.title.to_json(),
    "permission": [deny_all].to_json(),
  })
}

///|
struct PromptBody {
  model : ModelSelection
  system : String
  text : String
}

///|
impl ToJson for PromptBody with fn to_json(self) -> Json {
  Json::object({
    "model": ToJson::to_json(self.model),
    "format": Json::object({ "type": "text".to_json() }),
    "system": self.system.to_json(),
    "parts": Json::array([
      Json::object({ "type": "text".to_json(), "text": self.text.to_json() }),
    ]),
  })
}

///|
fn decode_session_id(response : Json) -> String raise {
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
  guard response is Json::Object(fields) else {
    fail("OpenCode returned a non-object prompt response")
  }
  guard fields.get("info") is Some(Json::Object(info)) else {
    fail("OpenCode prompt response is missing message info")
  }
  match info.get("error") {
    None | Some(Json::Null) => ()
    Some(error) => fail("OpenCode assistant failed: \{@debug.to_string(error)}")
  }
  guard fields.get("parts") is Some(Json::Array(parts)) else {
    fail("OpenCode prompt response is missing message parts")
  }
  let texts : Array[String] = []
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
  guard !texts.is_empty() else { fail("OpenCode assistant returned no text") }
  texts.join("")
}

///|
fn translation_system_prompt(lang : String) -> String {
  [
    "You are a markdown translator. Translate the user's input markdown to \{lang}.",
    "Strict rules:",
    "- Preserve all code blocks, inline code, links, HTML tags, and YAML/TOML frontmatter exactly as-is (do not translate code, URLs, fence languages, or attribute values).",
    "- Translate prose in headings, paragraphs, lists, blockquotes, and table cells.",
    "- Keep the original markdown structure (heading levels, list markers, blank lines).",
    "- Output ONLY the translated markdown. No commentary, no explanation, no fence wrapping.",
  ].join("\n")
}

///|
async fn translate_markdown(
  lang : String,
  model : ModelSelection,
  text : String,
) -> String {
  @async.with_task_group() <| group => {
    let server = @opencode.create_opencode_server(group)
    let result = try {
      let client = server.moonllm_config().timeout_ms(180000).build()
      let session = client.post_json(
        "/session",
        ToJson::to_json(SessionCreateBody::{ title: "mdt-translate" }),
      )
      let session_id = decode_session_id(session)
      client.post_json(
        "/session/\{session_id}/message",
        ToJson::to_json(PromptBody::{
          model,
          system: translation_system_prompt(lang),
          text,
        }),
      )
      |> decode_assistant_text
    } catch {
      error => {
        server.close()
        raise error
      }
    }
    server.close()
    result
  }
}
