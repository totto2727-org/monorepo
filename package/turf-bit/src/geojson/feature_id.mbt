///|
/// Feature ID.
/// https://tools.ietf.org/html/rfc7946#section-3.2
pub enum FeatureID {
  StringID(String)
  NumberID(Double)
} derive(Show, Eq, Hash, Compare)

///|
pub fn FeatureID::string(s : String) -> FeatureID {
  StringID(s)
}

///|
pub fn FeatureID::number(n : Double) -> FeatureID {
  NumberID(n)
}

///|
pub impl ToJson for FeatureID with to_json(self) {
  match self {
    FeatureID::StringID(s) => s.to_json()
    FeatureID::NumberID(n) => n.to_json()
  }
}

///|
pub impl FromJson for FeatureID with from_json(json, path) {
  match json {
    String(s) => FeatureID::StringID(s)
    Number(n, ..) => FeatureID::NumberID(n)
    _ => raise @json.JsonDecodeError((path, "Invalid Feature ID"))
  }
}
