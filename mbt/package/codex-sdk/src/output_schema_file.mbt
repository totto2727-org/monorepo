// Direct port of https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/outputSchemaFile.ts

///| Stores the optional schema path and the directory needed for cleanup.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/outputSchemaFile.ts#L5-L8
///| Type difference: MoonBit represents the cleanup closure as a method and retains its directory as private state.
priv struct OutputSchemaFile {
  schema_path : @path.Path?
  schema_directory : String?
}

///| Creates the temporary schema file and removes it if writing fails.
///| Upstream: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/outputSchemaFile.ts#L10-L36
///| Type difference: Json replaces TypeScript unknown and Path replaces filesystem strings.
async fn create_output_schema_file(
  schema : Json?,
) -> OutputSchemaFile raise {
  match schema {
    None => { schema_path: None, schema_directory: None }
    Some(Json::Object(_) as schema) => {
      let schema_directory = @fs.tmpdir(prefix="codex-output-schema-")
      let schema_path = @path.Path(schema_directory)
        |> @path.Path::join(@path.Path("schema.json"))
      let write_result = try? @fs.write_file(
        "\{schema_path}",
        schema.stringify(),
        create_mode=CreateOrTruncate,
      )
      match write_result {
        Ok(_) => { schema_path: Some(schema_path), schema_directory: Some(schema_directory) }
        Err(error) => {
          @fs.rmdir(schema_directory, recursive=true) catch { _ => () }
          raise error
        }
      }
    }
    Some(_) =>
      raise InvalidOutputSchema(message="output_schema must be a plain JSON object")
  }
}

///| Removes the temporary schema directory while suppressing cleanup failures.
///| Upstream cleanup closure: https://github.com/openai/codex/blob/f201c30c52a35f819262865a53df94b6f4ea7a50/sdk/typescript/src/outputSchemaFile.ts#L21-L27
///| Type difference: this method replaces the upstream cleanup closure stored in OutputSchemaFile.
async fn OutputSchemaFile::cleanup(self : OutputSchemaFile) -> Unit {
  if self.schema_directory is Some(directory) {
    @fs.rmdir(directory, recursive=true) catch { _ => () }
  }
}
