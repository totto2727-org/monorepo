///|
/// Main client for interacting with the OpenCode agent through its CLI.
pub struct OpenCode {
  priv exec : OpenCodeExec
}

///|
/// Construct an OpenCode CLI client.
pub fn OpenCode::OpenCode(
  options? : OpenCodeOptions = OpenCodeOptions::OpenCodeOptions(),
) -> OpenCode {
  {
    exec: OpenCodeExec::OpenCodeExec(
      options.opencode_path_override,
      options.env,
      options.config,
    ),
  }
}

///|
/// Start a new persisted OpenCode session.
pub fn OpenCode::start_thread(
  self : OpenCode,
  options? : ThreadOptions = ThreadOptions::ThreadOptions(),
) -> Thread {
  Thread::Thread(self.exec, options)
}

///|
/// Resume a persisted OpenCode session by identifier.
pub fn OpenCode::resume_thread(
  self : OpenCode,
  id : String,
  options? : ThreadOptions = ThreadOptions::ThreadOptions(),
) -> Thread {
  Thread::Thread(self.exec, options, id~)
}
