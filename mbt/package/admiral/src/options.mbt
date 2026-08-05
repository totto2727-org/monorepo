///|
/// sentinel value for "no short flag"
let no_short : Char = '\u0000'

///|
fn[T] option_def(
  name : String,
  config : String?,
  type_ : OptionType,
  short : Char,
  description : String,
  env : String?,
  required : Bool,
  default_value : String?,
  multiple : Bool,
  interactive : Bool,
) -> OptionDef[T] {
  {
    name,
    config,
    metadata: {
      type_,
      short,
      description,
      env,
      required,
      default_value,
      multiple,
      interactive,
    },
  }
}

///|
pub fn string(
  name : String,
  short? : Char = '\u0000',
  description? : String = "",
  env? : String,
  config? : String,
  required? : Bool = false,
  default? : String? = None,
  interactive? : Bool = false,
) -> OptionDef[String] {
  option_def(
    name,
    config,
    StringOpt,
    short,
    description,
    env,
    default is None && required,
    default,
    false,
    interactive,
  )
}

///|
pub fn strings(
  name : String,
  short? : Char = '\u0000',
  description? : String = "",
  env? : String,
  config? : String,
  required? : Bool = false,
  interactive? : Bool = false,
) -> OptionDef[Array[String]] {
  option_def(
    name,
    config,
    StringOpt,
    short,
    description,
    env,
    required,
    None,
    true,
    interactive,
  )
}

///|
pub fn bool(
  name : String,
  short? : Char = '\u0000',
  description? : String = "",
  env? : String,
  config? : String,
  interactive? : Bool = false,
) -> OptionDef[Bool] {
  option_def(
    name,
    config,
    BoolOpt,
    short,
    description,
    env,
    false,
    None,
    false,
    interactive,
  )
}

///|
pub fn int(
  name : String,
  short? : Char = '\u0000',
  description? : String = "",
  env? : String,
  config? : String,
  required? : Bool = false,
  default? : Int? = None,
  interactive? : Bool = false,
) -> OptionDef[Int] {
  option_def(
    name,
    config,
    IntOpt,
    short,
    description,
    env,
    default is None && required,
    default.map(fn(value) { value.to_string() }),
    false,
    interactive,
  )
}

///|
pub fn ints(
  name : String,
  short? : Char = '\u0000',
  description? : String = "",
  env? : String,
  config? : String,
  required? : Bool = false,
  interactive? : Bool = false,
) -> OptionDef[Array[Int]] {
  option_def(
    name,
    config,
    IntOpt,
    short,
    description,
    env,
    required,
    None,
    true,
    interactive,
  )
}

///|
pub fn int64(
  name : String,
  short? : Char = '\u0000',
  description? : String = "",
  env? : String,
  config? : String,
  required? : Bool = false,
  default? : Int64? = None,
  interactive? : Bool = false,
) -> OptionDef[Int64] {
  option_def(
    name,
    config,
    Int64Opt,
    short,
    description,
    env,
    default is None && required,
    default.map(fn(value) { value.to_string() }),
    false,
    interactive,
  )
}

///|
pub fn int64s(
  name : String,
  short? : Char = '\u0000',
  description? : String = "",
  env? : String,
  config? : String,
  required? : Bool = false,
  interactive? : Bool = false,
) -> OptionDef[Array[Int64]] {
  option_def(
    name,
    config,
    Int64Opt,
    short,
    description,
    env,
    required,
    None,
    true,
    interactive,
  )
}

///|
pub fn uint(
  name : String,
  short? : Char = '\u0000',
  description? : String = "",
  env? : String,
  config? : String,
  required? : Bool = false,
  default? : UInt? = None,
  interactive? : Bool = false,
) -> OptionDef[UInt] {
  option_def(
    name,
    config,
    UIntOpt,
    short,
    description,
    env,
    default is None && required,
    default.map(fn(value) { value.to_string() }),
    false,
    interactive,
  )
}

///|
pub fn uints(
  name : String,
  short? : Char = '\u0000',
  description? : String = "",
  env? : String,
  config? : String,
  required? : Bool = false,
  interactive? : Bool = false,
) -> OptionDef[Array[UInt]] {
  option_def(
    name,
    config,
    UIntOpt,
    short,
    description,
    env,
    required,
    None,
    true,
    interactive,
  )
}

///|
pub fn uint64(
  name : String,
  short? : Char = '\u0000',
  description? : String = "",
  env? : String,
  config? : String,
  required? : Bool = false,
  default? : UInt64? = None,
  interactive? : Bool = false,
) -> OptionDef[UInt64] {
  option_def(
    name,
    config,
    UInt64Opt,
    short,
    description,
    env,
    default is None && required,
    default.map(fn(value) { value.to_string() }),
    false,
    interactive,
  )
}

///|
pub fn uint64s(
  name : String,
  short? : Char = '\u0000',
  description? : String = "",
  env? : String,
  config? : String,
  required? : Bool = false,
  interactive? : Bool = false,
) -> OptionDef[Array[UInt64]] {
  option_def(
    name,
    config,
    UInt64Opt,
    short,
    description,
    env,
    required,
    None,
    true,
    interactive,
  )
}

///|
pub fn double(
  name : String,
  short? : Char = '\u0000',
  description? : String = "",
  env? : String,
  config? : String,
  required? : Bool = false,
  default? : Double? = None,
  interactive? : Bool = false,
) -> OptionDef[Double] {
  option_def(
    name,
    config,
    DoubleOpt,
    short,
    description,
    env,
    default is None && required,
    default.map(fn(value) { value.to_string() }),
    false,
    interactive,
  )
}

///|
pub fn doubles(
  name : String,
  short? : Char = '\u0000',
  description? : String = "",
  env? : String,
  config? : String,
  required? : Bool = false,
  interactive? : Bool = false,
) -> OptionDef[Array[Double]] {
  option_def(
    name,
    config,
    DoubleOpt,
    short,
    description,
    env,
    required,
    None,
    true,
    interactive,
  )
}
