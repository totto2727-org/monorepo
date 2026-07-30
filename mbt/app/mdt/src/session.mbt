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
fn ModelSelection::to_string(self : ModelSelection) -> String {
  "\{self.provider_id}/\{self.model_id}"
}

///|
fn translation_opencode_config() -> @opencode.OpenCodeConfigObject {
  { "permission": @opencode.ConfigString("deny") }
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
fn translation_prompt(lang : String, text : String) -> String {
  [translation_system_prompt(lang), "", "Input markdown:", text].join("\n")
}

///|
async fn translate_markdown_with_client(
  client : @opencode.OpenCode,
  lang : String,
  model : ModelSelection,
  text : String,
) -> String {
  client
  .start_thread(
    options=@opencode.ThreadOptions::ThreadOptions(
      model=model.to_string(),
      title="mdt-translate",
    ),
  )
  .run(@opencode.Prompt(translation_prompt(lang, text))).final_response
}

///|
async fn translate_markdown(
  lang : String,
  model : ModelSelection,
  text : String,
) -> String {
  let client = @opencode.OpenCode::OpenCode(
    options=@opencode.OpenCodeOptions::OpenCodeOptions(
      config=translation_opencode_config(),
    ),
  )
  translate_markdown_with_client(client, lang, model, text)
}
