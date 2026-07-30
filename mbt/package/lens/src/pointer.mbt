///|
priv enum PointerSegment {
  Key(String)
  Index(Int)
} derive(Eq, Debug)

///|
/// An immutable JSON Pointer identifying a location in a JSON document.
pub struct Pointer {
  priv segments : Array[PointerSegment]
} derive(Eq, Debug)

///|
fn Pointer::root() -> Pointer {
  Pointer::{ segments: [] }
}

///|
fn Pointer::key(self : Pointer, key : String) -> Pointer {
  Pointer::{ segments: [..self.segments, Key(key)] }
}

///|
fn Pointer::index(self : Pointer, index : Int) -> Pointer {
  Pointer::{ segments: [..self.segments, Index(index)] }
}

///|
fn Pointer::append(self : Pointer, suffix : Pointer) -> Pointer {
  Pointer::{ segments: [..self.segments, ..suffix.segments] }
}

///|
fn Pointer::prepend_index(self : Pointer, index : Int) -> Pointer {
  Pointer::root().index(index).append(self)
}

///|
fn escape_pointer_key(key : String) -> String {
  key.replace_all(old="~", new="~0").replace_all(old="/", new="~1")
}

///|
/// Returns the RFC 6901 string representation of this pointer.
pub fn Pointer::to_string(self : Pointer) -> String {
  let output = StringBuilder()
  for segment in self.segments {
    output.write_char('/')
    match segment {
      Key(key) => output.write_string(escape_pointer_key(key))
      Index(index) => output.write_object(index)
    }
  }
  output.to_string()
}
