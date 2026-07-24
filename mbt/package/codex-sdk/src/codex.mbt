// Direct port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/codex.ts

///| Main client for interacting with the Codex agent.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/codex.ts#L6-L13
pub struct Codex {
  priv exec : CodexExec
  priv options : CodexOptions
}

///| Constructs a Codex client.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/codex.ts#L15-L19
pub fn Codex::Codex(
  options? : CodexOptions = CodexOptions::CodexOptions(),
) -> Codex {
  {
    exec: CodexExec::CodexExec(
      options.codex_path_override,
      options.env,
      options.config,
    ),
    options,
  }
}

///| Starts a new persisted conversation with an agent.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/codex.ts#L21-L27
pub fn Codex::start_thread(
  self : Codex,
  options? : ThreadOptions = ThreadOptions::ThreadOptions(),
) -> Thread {
  Thread::Thread(self.exec, self.options, options)
}

///| Resumes a persisted conversation by thread identifier.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/codex.ts#L29-L38
pub fn Codex::resume_thread(
  self : Codex,
  id : String,
  options? : ThreadOptions = ThreadOptions::ThreadOptions(),
) -> Thread {
  Thread::Thread(self.exec, self.options, options, id=id)
}
