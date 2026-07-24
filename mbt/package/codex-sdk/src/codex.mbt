///| Main client for interacting with the Codex agent.
pub struct Codex {
  priv exec : CodexExec
  priv options : CodexOptions
}

///| Constructs a Codex client.
pub fn Codex::Codex(
  options? : CodexOptions = CodexOptions::CodexOptions(),
) -> Codex {
  { exec: CodexExec::CodexExec(options), options }
}

///| Starts a new persisted conversation with an agent.
pub fn Codex::start_thread(
  self : Codex,
  options? : ThreadOptions = ThreadOptions::ThreadOptions(),
) -> Thread {
  Thread::Thread(self.exec, self.options, options)
}

///| Resumes a persisted conversation by thread identifier.
pub fn Codex::resume_thread(
  self : Codex,
  id : String,
  options? : ThreadOptions = ThreadOptions::ThreadOptions(),
) -> Thread {
  Thread::Thread(self.exec, self.options, options, id=id)
}
