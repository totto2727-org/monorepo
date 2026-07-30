///|
/// Options applied to every turn in one OpenCode session.
pub(all) struct ThreadOptions {
  model : String?
  agent : String?
  working_directory : @path.Path?
  variant : String?
  title : String?
  thinking : Bool
} derive(Eq)

///|
/// Construct optional OpenCode session settings.
pub fn ThreadOptions::ThreadOptions(
  model? : String,
  agent? : String,
  working_directory? : @path.Path,
  variant? : String,
  title? : String,
  thinking? : Bool = false,
) -> ThreadOptions {
  { model, agent, working_directory, variant, title, thinking }
}
