///|
fn[T] position_def(
  name : String,
  config : String?,
  type_ : OptionType,
  description : String,
  required : Bool,
  multiple : Bool,
) -> PositionDef[T] {
  { name, config, metadata: { type_, description, required, multiple } }
}

///|
pub fn position_string(
  name : String,
  description? : String = "",
  config? : String,
  required? : Bool = false,
) -> PositionDef[String] {
  position_def(name, config, StringOpt, description, required, false)
}

///|
pub fn position_strings(
  name : String,
  description? : String = "",
  config? : String,
  required? : Bool = false,
) -> PositionDef[Array[String]] {
  position_def(name, config, StringOpt, description, required, true)
}

///|
pub fn position_int(
  name : String,
  description? : String = "",
  config? : String,
  required? : Bool = false,
) -> PositionDef[Int] {
  position_def(name, config, IntOpt, description, required, false)
}

///|
pub fn position_ints(
  name : String,
  description? : String = "",
  config? : String,
  required? : Bool = false,
) -> PositionDef[Array[Int]] {
  position_def(name, config, IntOpt, description, required, true)
}

///|
pub fn position_int64(
  name : String,
  description? : String = "",
  config? : String,
  required? : Bool = false,
) -> PositionDef[Int64] {
  position_def(name, config, Int64Opt, description, required, false)
}

///|
pub fn position_int64s(
  name : String,
  description? : String = "",
  config? : String,
  required? : Bool = false,
) -> PositionDef[Array[Int64]] {
  position_def(name, config, Int64Opt, description, required, true)
}

///|
pub fn position_uint(
  name : String,
  description? : String = "",
  config? : String,
  required? : Bool = false,
) -> PositionDef[UInt] {
  position_def(name, config, UIntOpt, description, required, false)
}

///|
pub fn position_uints(
  name : String,
  description? : String = "",
  config? : String,
  required? : Bool = false,
) -> PositionDef[Array[UInt]] {
  position_def(name, config, UIntOpt, description, required, true)
}

///|
pub fn position_uint64(
  name : String,
  description? : String = "",
  config? : String,
  required? : Bool = false,
) -> PositionDef[UInt64] {
  position_def(name, config, UInt64Opt, description, required, false)
}

///|
pub fn position_uint64s(
  name : String,
  description? : String = "",
  config? : String,
  required? : Bool = false,
) -> PositionDef[Array[UInt64]] {
  position_def(name, config, UInt64Opt, description, required, true)
}

///|
pub fn position_double(
  name : String,
  description? : String = "",
  config? : String,
  required? : Bool = false,
) -> PositionDef[Double] {
  position_def(name, config, DoubleOpt, description, required, false)
}

///|
pub fn position_doubles(
  name : String,
  description? : String = "",
  config? : String,
  required? : Bool = false,
) -> PositionDef[Array[Double]] {
  position_def(name, config, DoubleOpt, description, required, true)
}
