///|
pub fn[Metadata] Context::get_strings(
  self : Context,
  argument : ArgDef[Array[String], Metadata],
) -> Array[String] raise @json.JsonDecodeError {
  if should_use_config(self.sources.get(argument.name)) {
    match argument.config {
      Some(key) =>
        match self.config.get(key) {
          Some(value) => return @json.from_json(value)
          None => ()
        }
      None => ()
    }
  }
  match self.values.get(argument.name) {
    Some(values) => values
    None => []
  }
}

///|
pub fn[Metadata] Context::get_strings_required(
  self : Context,
  argument : ArgDef[Array[String], Metadata],
) -> NonEmptyArray[String] raise {
  let all = self.get_strings(argument)
  match all {
    [first, ..] => { first, rest: all[1:], all }
    [] => fail("missing required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_ints(
  self : Context,
  argument : ArgDef[Array[Int], Metadata],
) -> Array[Int] raise {
  if should_use_config(self.sources.get(argument.name)) {
    match argument.config {
      Some(key) =>
        match self.config.get(key) {
          Some(value) => return @json.from_json(value)
          None => ()
        }
      None => ()
    }
  }
  match self.values.get(argument.name) {
    Some(values) => values.map(value => @string.parse_int(value, base=10))
    None => []
  }
}

///|
pub fn[Metadata] Context::get_ints_required(
  self : Context,
  argument : ArgDef[Array[Int], Metadata],
) -> NonEmptyArray[Int] raise {
  let all = self.get_ints(argument)
  match all {
    [first, ..] => { first, rest: all[1:], all }
    [] => fail("missing required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_int64s(
  self : Context,
  argument : ArgDef[Array[Int64], Metadata],
) -> Array[Int64] raise {
  if should_use_config(self.sources.get(argument.name)) {
    match argument.config {
      Some(key) =>
        match self.config.get(key) {
          Some(value) => return @json.from_json(value)
          None => ()
        }
      None => ()
    }
  }
  match self.values.get(argument.name) {
    Some(values) => values.map(value => @string.parse_int64(value, base=10))
    None => []
  }
}

///|
pub fn[Metadata] Context::get_int64s_required(
  self : Context,
  argument : ArgDef[Array[Int64], Metadata],
) -> NonEmptyArray[Int64] raise {
  let all = self.get_int64s(argument)
  match all {
    [first, ..] => { first, rest: all[1:], all }
    [] => fail("missing required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_uints(
  self : Context,
  argument : ArgDef[Array[UInt], Metadata],
) -> Array[UInt] raise {
  if should_use_config(self.sources.get(argument.name)) {
    match argument.config {
      Some(key) =>
        match self.config.get(key) {
          Some(value) => return @json.from_json(value)
          None => ()
        }
      None => ()
    }
  }
  match self.values.get(argument.name) {
    Some(values) => values.map(value => @string.parse_uint(value, base=10))
    None => []
  }
}

///|
pub fn[Metadata] Context::get_uints_required(
  self : Context,
  argument : ArgDef[Array[UInt], Metadata],
) -> NonEmptyArray[UInt] raise {
  let all = self.get_uints(argument)
  match all {
    [first, ..] => { first, rest: all[1:], all }
    [] => fail("missing required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_uint64s(
  self : Context,
  argument : ArgDef[Array[UInt64], Metadata],
) -> Array[UInt64] raise {
  if should_use_config(self.sources.get(argument.name)) {
    match argument.config {
      Some(key) =>
        match self.config.get(key) {
          Some(value) => return @json.from_json(value)
          None => ()
        }
      None => ()
    }
  }
  match self.values.get(argument.name) {
    Some(values) => values.map(value => @string.parse_uint64(value, base=10))
    None => []
  }
}

///|
pub fn[Metadata] Context::get_uint64s_required(
  self : Context,
  argument : ArgDef[Array[UInt64], Metadata],
) -> NonEmptyArray[UInt64] raise {
  let all = self.get_uint64s(argument)
  match all {
    [first, ..] => { first, rest: all[1:], all }
    [] => fail("missing required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_doubles(
  self : Context,
  argument : ArgDef[Array[Double], Metadata],
) -> Array[Double] raise {
  if should_use_config(self.sources.get(argument.name)) {
    match argument.config {
      Some(key) =>
        match self.config.get(key) {
          Some(value) => return @json.from_json(value)
          None => ()
        }
      None => ()
    }
  }
  match self.values.get(argument.name) {
    Some(values) => values.map(value => @string.parse_double(value))
    None => []
  }
}

///|
pub fn[Metadata] Context::get_doubles_required(
  self : Context,
  argument : ArgDef[Array[Double], Metadata],
) -> NonEmptyArray[Double] raise {
  let all = self.get_doubles(argument)
  match all {
    [first, ..] => { first, rest: all[1:], all }
    [] => fail("missing required argument: " + argument.name)
  }
}
