///| One structured input entry sent to the agent.
pub(all) enum UserInput {
  Text(String)
  LocalImage(@path.Path)
} derive(Eq)

///| Input accepted by a thread turn.
pub(all) enum Input {
  Prompt(String)
  UserInputs(Array[UserInput])
} derive(Eq)

priv struct NormalizedInput {
  prompt : String
  images : Array[@path.Path]
}

fn normalize_input(input : Input) -> NormalizedInput {
  match input {
    Prompt(prompt) => { prompt, images: [] }
    UserInputs(items) => {
      let prompt = items
        .iter()
        .filter_map(item =>
          match item {
            Text(text) => Some(text)
            LocalImage(_) => None
          })
        .join("\n\n")
      let images = items
        .iter()
        .filter_map(item =>
          match item {
            Text(_) => None
            LocalImage(path) => Some(path)
          })
        .collect()
      { prompt, images }
    }
  }
}
