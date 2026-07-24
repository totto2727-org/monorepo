///|
fn option_type_to_string(t : OptionType) -> String {
  match t {
    StringOpt => "string"
    BoolOpt => "bool"
    IntOpt => "int"
    Int64Opt => "int64"
    UIntOpt => "uint"
    UInt64Opt => "uint64"
    DoubleOpt => "double"
  }
}

///|
fn option_def_to_json(opt : StoredOption) -> Json {
  let metadata = opt.metadata
  let m : Map[String, Json] = Map([])
  m["type"] = option_type_to_string(metadata.type_).to_json()
  m["description"] = metadata.description.to_json()
  m["required"] = metadata.required.to_json()
  m["multiple"] = metadata.multiple.to_json()
  if metadata.type_ == BoolOpt {
    m["style"] = "flag".to_json()
  }
  if metadata.short != no_short {
    m["short"] = metadata.short.to_string().to_json()
  }
  match metadata.env {
    Some(name) => m["env"] = name.to_json()
    None => ()
  }
  match opt.config {
    Some(key) => m["config"] = key.to_json()
    None => ()
  }
  match metadata.default_value {
    Some(v) => m["default"] = v.to_json()
    None => ()
  }
  Json::object(m)
}

///|
fn position_def_to_json(position : StoredPosition) -> Json {
  let metadata = position.metadata
  let m : Map[String, Json] = Map([])
  m["type"] = option_type_to_string(metadata.type_).to_json()
  m["description"] = metadata.description.to_json()
  m["required"] = metadata.required.to_json()
  m["multiple"] = metadata.multiple.to_json()
  match position.config {
    Some(key) => m["config"] = key.to_json()
    None => ()
  }
  Json::object(m)
}

///|
fn generate_example(cmd_path : String, options : Array[StoredOption]) -> String {
  let parts : Array[String] = [cmd_path]
  for opt in options {
    if opt.metadata.required {
      parts.push("--" + opt.name + " <" + opt.name + ">")
    }
  }
  parts.join(" ")
}

///|
fn command_def_to_json(cmd : CommandDef, cmd_path : String) -> Json {
  let m : Map[String, Json] = Map([])
  m["description"] = cmd.description.to_json()
  if cmd.options.length() > 0 {
    let opts : Map[String, Json] = Map([])
    for opt in cmd.options {
      opts[opt.name] = option_def_to_json(opt)
    }
    m["options"] = Json::object(opts)
  }
  if cmd.positionals.length() > 0 {
    let poss : Map[String, Json] = Map([])
    for pos in cmd.positionals {
      poss[pos.name] = position_def_to_json(pos)
    }
    m["positionals"] = Json::object(poss)
  }
  if cmd.examples.length() > 0 {
    m["examples"] = Json::array(cmd.examples.map(fn(e) { e.to_json() }))
  } else if cmd.options.length() > 0 || cmd.positionals.length() > 0 {
    let ex = generate_example(cmd_path, cmd.options)
    m["examples"] = Json::array([ex.to_json()])
  }
  if cmd.subcommands.length() > 0 {
    let subs : Map[String, Json] = Map([])
    for sub in cmd.subcommands {
      let sub_path = cmd_path + " " + sub.name
      subs[sub.name] = command_def_to_json(sub, sub_path)
    }
    m["commands"] = Json::object(subs)
  }
  Json::object(m)
}

///|
pub fn CliApp::render_schema_json(self : CliApp) -> Json {
  let m : Map[String, Json] = Map([])
  m["name"] = self.name.to_json()
  m["version"] = self.version.to_json()
  m["description"] = self.description.to_json()
  if self.root_options.length() > 0 {
    let opts : Map[String, Json] = Map([])
    for opt in self.root_options {
      opts[opt.name] = option_def_to_json(opt)
    }
    m["options"] = Json::object(opts)
  }
  if self.root_positionals.length() > 0 {
    let positionals : Map[String, Json] = Map([])
    for position in self.root_positionals {
      positionals[position.name] = position_def_to_json(position)
    }
    m["positionals"] = Json::object(positionals)
  }
  if self.commands.length() > 0 {
    let cmds : Map[String, Json] = Map([])
    for cmd in self.commands {
      let cmd_path = self.name + " " + cmd.name
      cmds[cmd.name] = command_def_to_json(cmd, cmd_path)
    }
    m["commands"] = Json::object(cmds)
  }
  Json::object(m)
}

///|
pub fn CliApp::render_schema(self : CliApp) -> String {
  self.render_schema_json().stringify()
}
