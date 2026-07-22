///|
fn[T, Metadata] Context::get_all_values(
  self : Context,
  argument : ArgDef[Array[T], Metadata],
) -> Array[String]? {
  self.values.get(argument.name)
}

///|
pub fn[Metadata] Context::get_strings(
  self : Context,
  argument : ArgDef[Array[String], Metadata],
) -> Array[String]? {
  self.get_all_values(argument)
}

///|
pub fn[Metadata] Context::get_strings_required(
  self : Context,
  argument : ArgDef[Array[String], Metadata],
) -> Array[String] raise {
  match self.get_strings(argument) {
    Some(values) => values
    None => fail("missing required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_ints(
  self : Context,
  argument : ArgDef[Array[Int], Metadata],
) -> Array[Int]? {
  let values = match self.get_all_values(argument) {
    Some(values) => values
    None => return None
  }
  let parsed : Array[Int] = []
  for value in values {
    let item = @string.parse_int(value, base=10) catch { _ => return None }
    parsed.push(item)
  }
  Some(parsed)
}

///|
pub fn[Metadata] Context::get_ints_required(
  self : Context,
  argument : ArgDef[Array[Int], Metadata],
) -> Array[Int] raise {
  match self.get_ints(argument) {
    Some(values) => values
    None => fail("missing or invalid required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_int64s(
  self : Context,
  argument : ArgDef[Array[Int64], Metadata],
) -> Array[Int64]? {
  let values = match self.get_all_values(argument) {
    Some(values) => values
    None => return None
  }
  let parsed : Array[Int64] = []
  for value in values {
    let item = @string.parse_int64(value, base=10) catch { _ => return None }
    parsed.push(item)
  }
  Some(parsed)
}

///|
pub fn[Metadata] Context::get_int64s_required(
  self : Context,
  argument : ArgDef[Array[Int64], Metadata],
) -> Array[Int64] raise {
  match self.get_int64s(argument) {
    Some(values) => values
    None => fail("missing or invalid required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_uints(
  self : Context,
  argument : ArgDef[Array[UInt], Metadata],
) -> Array[UInt]? {
  let values = match self.get_all_values(argument) {
    Some(values) => values
    None => return None
  }
  let parsed : Array[UInt] = []
  for value in values {
    let item = @string.parse_uint(value, base=10) catch { _ => return None }
    parsed.push(item)
  }
  Some(parsed)
}

///|
pub fn[Metadata] Context::get_uints_required(
  self : Context,
  argument : ArgDef[Array[UInt], Metadata],
) -> Array[UInt] raise {
  match self.get_uints(argument) {
    Some(values) => values
    None => fail("missing or invalid required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_uint64s(
  self : Context,
  argument : ArgDef[Array[UInt64], Metadata],
) -> Array[UInt64]? {
  let values = match self.get_all_values(argument) {
    Some(values) => values
    None => return None
  }
  let parsed : Array[UInt64] = []
  for value in values {
    let item = @string.parse_uint64(value, base=10) catch { _ => return None }
    parsed.push(item)
  }
  Some(parsed)
}

///|
pub fn[Metadata] Context::get_uint64s_required(
  self : Context,
  argument : ArgDef[Array[UInt64], Metadata],
) -> Array[UInt64] raise {
  match self.get_uint64s(argument) {
    Some(values) => values
    None => fail("missing or invalid required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_doubles(
  self : Context,
  argument : ArgDef[Array[Double], Metadata],
) -> Array[Double]? {
  let values = match self.get_all_values(argument) {
    Some(values) => values
    None => return None
  }
  let parsed : Array[Double] = []
  for value in values {
    let item = @string.parse_double(value) catch { _ => return None }
    parsed.push(item)
  }
  Some(parsed)
}

///|
pub fn[Metadata] Context::get_doubles_required(
  self : Context,
  argument : ArgDef[Array[Double], Metadata],
) -> Array[Double] raise {
  match self.get_doubles(argument) {
    Some(values) => values
    None => fail("missing or invalid required argument: " + argument.name)
  }
}
