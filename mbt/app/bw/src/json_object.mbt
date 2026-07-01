///|
fn put_json_if_some(
  object : Map[String, Json],
  key : String,
  value : Json?,
) -> Unit {
  match value {
    Some(value) => object.set(key, value)
    None => ()
  }
}
