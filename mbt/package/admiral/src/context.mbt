///|
/// Boolean options are flags stored separately from positional values.
/// Their absence means `false`, so this getter intentionally accepts only `OptionDef`.
pub fn Context::get_bool(
  self : Context,
  option : OptionDef[Bool],
) -> Bool raise @json.JsonDecodeError {
  match self.interactive_flags.get(option.name) {
    Some(value) => return value
    None => ()
  }
  if should_use_config(self.sources.get(option.name)) {
    match option.config {
      Some(key) =>
        match self.config.get(key) {
          Some(value) => return @json.from_json(value)
          None => ()
        }
      None => ()
    }
  }
  self.flags.contains(option.name)
}

///|
fn should_use_config(source : @argparse.ValueSource?) -> Bool {
  match source {
    Some(@argparse.ValueSource::Argv) | Some(@argparse.ValueSource::Env) =>
      false
    Some(@argparse.ValueSource::Default) | None => true
  }
}

///|
pub fn[Metadata] Context::get_string(
  self : Context,
  argument : ArgDef[String, Metadata],
) -> String? raise @json.JsonDecodeError {
  match self.interactive_values.get(argument.name) {
    Some([value, ..]) => return Some(value)
    Some([]) => return None
    None => ()
  }
  if should_use_config(self.sources.get(argument.name)) {
    match argument.config {
      Some(key) =>
        match self.config.get(key) {
          Some(value) => return Some(@json.from_json(value))
          None => ()
        }
      None => ()
    }
  }
  match self.values.get(argument.name) {
    Some([value, ..]) => Some(value)
    Some([]) | None => None
  }
}

///|
pub fn[Metadata] Context::get_string_required(
  self : Context,
  argument : ArgDef[String, Metadata],
) -> String raise {
  match self.get_string(argument) {
    Some(value) => value
    None => fail("missing required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_int(
  self : Context,
  argument : ArgDef[Int, Metadata],
) -> Int? raise {
  match self.interactive_values.get(argument.name) {
    Some([value, ..]) => return Some(@string.parse_int(value, base=10))
    Some([]) => return None
    None => ()
  }
  if should_use_config(self.sources.get(argument.name)) {
    match argument.config {
      Some(key) =>
        match self.config.get(key) {
          Some(value) => return Some(@json.from_json(value))
          None => ()
        }
      None => ()
    }
  }
  match self.values.get(argument.name) {
    Some([value, ..]) => Some(@string.parse_int(value, base=10))
    Some([]) | None => None
  }
}

///|
pub fn[Metadata] Context::get_int_required(
  self : Context,
  argument : ArgDef[Int, Metadata],
) -> Int raise {
  match self.get_int(argument) {
    Some(value) => value
    None => fail("missing required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_int64(
  self : Context,
  argument : ArgDef[Int64, Metadata],
) -> Int64? raise {
  match self.interactive_values.get(argument.name) {
    Some([value, ..]) => return Some(@string.parse_int64(value, base=10))
    Some([]) => return None
    None => ()
  }
  if should_use_config(self.sources.get(argument.name)) {
    match argument.config {
      Some(key) =>
        match self.config.get(key) {
          Some(value) => return Some(@json.from_json(value))
          None => ()
        }
      None => ()
    }
  }
  match self.values.get(argument.name) {
    Some([value, ..]) => Some(@string.parse_int64(value, base=10))
    Some([]) | None => None
  }
}

///|
pub fn[Metadata] Context::get_int64_required(
  self : Context,
  argument : ArgDef[Int64, Metadata],
) -> Int64 raise {
  match self.get_int64(argument) {
    Some(value) => value
    None => fail("missing required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_uint(
  self : Context,
  argument : ArgDef[UInt, Metadata],
) -> UInt? raise {
  match self.interactive_values.get(argument.name) {
    Some([value, ..]) => return Some(@string.parse_uint(value, base=10))
    Some([]) => return None
    None => ()
  }
  if should_use_config(self.sources.get(argument.name)) {
    match argument.config {
      Some(key) =>
        match self.config.get(key) {
          Some(value) => return Some(@json.from_json(value))
          None => ()
        }
      None => ()
    }
  }
  match self.values.get(argument.name) {
    Some([value, ..]) => Some(@string.parse_uint(value, base=10))
    Some([]) | None => None
  }
}

///|
pub fn[Metadata] Context::get_uint_required(
  self : Context,
  argument : ArgDef[UInt, Metadata],
) -> UInt raise {
  match self.get_uint(argument) {
    Some(value) => value
    None => fail("missing required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_uint64(
  self : Context,
  argument : ArgDef[UInt64, Metadata],
) -> UInt64? raise {
  match self.interactive_values.get(argument.name) {
    Some([value, ..]) => return Some(@string.parse_uint64(value, base=10))
    Some([]) => return None
    None => ()
  }
  if should_use_config(self.sources.get(argument.name)) {
    match argument.config {
      Some(key) =>
        match self.config.get(key) {
          Some(value) => return Some(@json.from_json(value))
          None => ()
        }
      None => ()
    }
  }
  match self.values.get(argument.name) {
    Some([value, ..]) => Some(@string.parse_uint64(value, base=10))
    Some([]) | None => None
  }
}

///|
pub fn[Metadata] Context::get_uint64_required(
  self : Context,
  argument : ArgDef[UInt64, Metadata],
) -> UInt64 raise {
  match self.get_uint64(argument) {
    Some(value) => value
    None => fail("missing required argument: " + argument.name)
  }
}

///|
pub fn[Metadata] Context::get_double(
  self : Context,
  argument : ArgDef[Double, Metadata],
) -> Double? raise {
  match self.interactive_values.get(argument.name) {
    Some([value, ..]) => return Some(@string.parse_double(value))
    Some([]) => return None
    None => ()
  }
  if should_use_config(self.sources.get(argument.name)) {
    match argument.config {
      Some(key) =>
        match self.config.get(key) {
          Some(value) => return Some(@json.from_json(value))
          None => ()
        }
      None => ()
    }
  }
  match self.values.get(argument.name) {
    Some([value, ..]) => Some(@string.parse_double(value))
    Some([]) | None => None
  }
}

///|
pub fn[Metadata] Context::get_double_required(
  self : Context,
  argument : ArgDef[Double, Metadata],
) -> Double raise {
  match self.get_double(argument) {
    Some(value) => value
    None => fail("missing required argument: " + argument.name)
  }
}

///|
pub fn Context::get_subcommand(self : Context) -> (String, Context)? {
  self.subcommand
}
