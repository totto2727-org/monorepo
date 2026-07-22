///|
fn[T] position_def(
  name : String,
  type_ : OptionType,
  description : String,
  required : Bool,
  multiple : Bool,
) -> PositionDef[T] {
  { name, metadata: { type_, description, required, multiple } }
}

///|
pub fn position_string(
  name : String,
  description? : String = "",
  required? : Bool = false,
) -> PositionDef[String] {
  position_def(name, StringOpt, description, required, false)
}

///|
pub fn position_strings(
  name : String,
  description? : String = "",
  required? : Bool = false,
) -> PositionDef[Array[String]] {
  position_def(name, StringOpt, description, required, true)
}

///|
pub fn position_int(
  name : String,
  description? : String = "",
  required? : Bool = false,
) -> PositionDef[Int] {
  position_def(name, IntOpt, description, required, false)
}

///|
pub fn position_ints(
  name : String,
  description? : String = "",
  required? : Bool = false,
) -> PositionDef[Array[Int]] {
  position_def(name, IntOpt, description, required, true)
}

///|
pub fn position_int64(
  name : String,
  description? : String = "",
  required? : Bool = false,
) -> PositionDef[Int64] {
  position_def(name, Int64Opt, description, required, false)
}

///|
pub fn position_int64s(
  name : String,
  description? : String = "",
  required? : Bool = false,
) -> PositionDef[Array[Int64]] {
  position_def(name, Int64Opt, description, required, true)
}

///|
pub fn position_uint(
  name : String,
  description? : String = "",
  required? : Bool = false,
) -> PositionDef[UInt] {
  position_def(name, UIntOpt, description, required, false)
}

///|
pub fn position_uints(
  name : String,
  description? : String = "",
  required? : Bool = false,
) -> PositionDef[Array[UInt]] {
  position_def(name, UIntOpt, description, required, true)
}

///|
pub fn position_uint64(
  name : String,
  description? : String = "",
  required? : Bool = false,
) -> PositionDef[UInt64] {
  position_def(name, UInt64Opt, description, required, false)
}

///|
pub fn position_uint64s(
  name : String,
  description? : String = "",
  required? : Bool = false,
) -> PositionDef[Array[UInt64]] {
  position_def(name, UInt64Opt, description, required, true)
}

///|
pub fn position_double(
  name : String,
  description? : String = "",
  required? : Bool = false,
) -> PositionDef[Double] {
  position_def(name, DoubleOpt, description, required, false)
}

///|
pub fn position_doubles(
  name : String,
  description? : String = "",
  required? : Bool = false,
) -> PositionDef[Array[Double]] {
  position_def(name, DoubleOpt, description, required, true)
}
