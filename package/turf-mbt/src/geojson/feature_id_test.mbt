///|
test "FeatureID StringID to JSON" {
  let id = FeatureID::string("f1")
  @json.inspect(id, content="f1")
}

///|
test "FeatureID NumberID to JSON" {
  let id = FeatureID::number(123.45)
  @json.inspect(id, content=123.45)
}

///|
test "FeatureID StringID from JSON" {
  let id : FeatureID = @json.from_json("id-123")
  inspect(id, content="StringID(\"id-123\")")
}

///|
test "FeatureID NumberID from JSON" {
  let id : FeatureID = @json.from_json(456)
  inspect(id, content="NumberID(456)")
}

///|
test "panic_FeatureID from JSON error" {
  let _ : FeatureID = @json.from_json(true)

}
