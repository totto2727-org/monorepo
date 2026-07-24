priv struct OutputSchemaFile {
  schema_path : @path.Path?
  schema_directory : String?
}

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

async fn OutputSchemaFile::cleanup(self : OutputSchemaFile) -> Unit {
  if self.schema_directory is Some(directory) {
    @fs.rmdir(directory, recursive=true) catch { _ => () }
  }
}
