<!-- Derived from MoonBit documentation by moonbitlang -->
<!-- https://github.com/moonbitlang/moonbit-docs -->
<!-- Prose content (post July 4, 2024): CC BY-SA 4.0 -->
<!-- Code examples: Apache 2.0 -->
<!-- Modifications: Extracted and reformatted as Claude Code skill files -->

### Pattern Matching

Pattern matching allows us to match on specific pattern and bind data from data structures.

#### Simple Patterns

We can pattern match expressions against

- literals, such as boolean values, numbers, chars, strings, etc
- constants
- structs
- enums
- arrays
- maps
- JSONs

and so on. We can define identifiers to bind the matched values so that they can be used later.

```moonbit
const ONE = 1

fn match_int(x : Int) -> Unit {
  match x {
    0 => println("zero")
    ONE => println("one")
    value => println(value)
  }
}
```

We can use `_` as wildcards for the values we don't care about, and use `..` to ignore remaining fields of struct or enum, or array (see [array pattern]()).

```moonbit
struct Point3D {
  x : Int
  y : Int
  z : Int
}

fn match_point3D(p : Point3D) -> Unit {
  match p {
    { x: 0, .. } => println("on yz-plane")
    _ => println("not on yz-plane")
  }
}

enum Point[T] {
  Point2D(Int, Int, name~ : String, payload~ : T)
}

fn[T] match_point(p : Point[T]) -> Unit {
  match p {
    //! Point2D(0, 0) => println("2D origin")
    Point2D(0, 0, ..) => println("2D origin")
    Point2D(_) => println("2D point")
    _ => panic()
  }
}
```

We can use `as` to give a name to some pattern, and we can use `|` to match several cases at once. A variable name can only be bound once in a single pattern, and the same set of variables should be bound on both sides of `|` patterns.

```moonbit
match expr {
  //! Add(e1, e2) | Lit(e1) => ...
  Lit(n) as a => ...
  Add(e1, e2) | Mul(e1, e2) => ...
  ...
}
```

#### Array Pattern

Array patterns can be used to match on the following types to obtain their
corresponding elements or views:

| Type                                  | Element   | View         |
|---------------------------------------|-----------|--------------|
| Array[T], ArrayView[T], FixedArray[T] | T         | ArrayView[T] |
| Bytes, BytesView                      | Byte      | BytesView    |
| String, StringView                    | Char      | StringView   |

Array patterns have the following forms:

- `[]` : matching for empty array
- `[pa, pb, pc]` : matching for array of length three, and bind `pa`, `pb`, `pc`
  to the three elements
- `[pa, ..rest, pb]` : matching for array with at least two elements, and bind
  `pa` to the first element, `pb` to the last element, and `rest` to the
  remaining elements. the binder `rest` can be omitted if the rest of the
  elements are not needed. Arbitrary number of elements are allowed preceding
  and following the `..` part. Because `..` can match uncertain number of
  elements, it can appear at most once in an array pattern.

```moonbit
test {
  let ary = [1, 2, 3, 4]
  if ary is [a, b, .. rest] && a == 1 && b == 2 && rest.length() == 2 {
    inspect("a = \{a}, b = \{b}", content="a = 1, b = 2")
  } else {
    fail("")
  }
  guard ary is [.., a, b] else { fail("") }
  inspect("a = \{a}, b = \{b}", content="a = 3, b = 4")
}
```

Array patterns provide a unicode-safe way to manipulate strings, meaning that it
respects the code unit boundaries. For example, we can check if a string is a
palindrome:

```moonbit
test {
  fn palindrome(s : String) -> Bool {
    for view = s.view() {
      match view {
        [] | [_] => break true
        [a, .. rest, b] => if a == b { continue rest } else { break false }
      }
    }
  }

  inspect(palindrome("abba"), content="true")
  inspect(palindrome("中b中"), content="true")
  inspect(palindrome("文bb中"), content="false")
}
```

When there are consecutive char or byte constants in an array pattern, the
pattern spread `..` operator can be used to combine them to make the code look
cleaner. Note that in this case the `..` followed by string or bytes constant
matches exact number of elements so its usage is not limited to once.

```moonbit
const NO : Bytes = "no"

test {
  fn match_string(s : String) -> Bool {
    match s {
      [.. "yes", ..] => true // equivalent to ['y', 'e', 's', ..]
    }
  }

  fn match_bytes(b : Bytes) -> Bool {
    match b {
      [.. NO, ..] => false // equivalent to ['n', 'o', ..]
    }
  }
}
```

#### Bitstring Pattern

Bitstring patterns can match packed bit fields from byte containers. They are
supported on `BytesView`, `Bytes`, `Array[Byte]`, `FixedArray[Byte]`,
`ReadOnlyArray[Byte]`, and `ArrayView[Byte]`. Use explicit widths with
`be`/`le` suffixes to make endianness clear.
`be` supports widths 1..64; `le` is only defined for byte-aligned widths (8 \*
n), since little-endian order is defined on bytes. Without `..`, the pattern
must consume the entire view.

```moonbit
test {
  let packet : Bytes = b"\xD2\x10\x7F"
  let header : BytesView = packet[0:2]
  let (flag, kind, version, length) = match header {
    [u1be(flag), u3be(kind), u4be(version), u8be(length)] =>
      (flag, kind, version, length)
    _ => fail("bad header")
  }
  assert_eq(flag, 1)
  assert_eq(kind, 0b101)
  assert_eq(version, 0b0010)
  assert_eq(length, 16)
}
```

Use literal bit patterns to validate headers, and `..` to capture the remaining
data for the next parse step.

```moonbit
test {
  let data : Bytes = b"\xF1\xAA\xBB"
  let view : BytesView = data[0:]
  let tag = match view {
    [u4be(0b1111), u4be(tag), .. rest] => {
      assert_eq(rest, b"\xAA\xBB"[0:])
      tag
    }
    _ => fail("bad prefix")
  }
  assert_eq(tag, 0b0001)
}
```

Examples over common byte containers (note the `MutArrayView` slice):

```moonbit
test {
  let b : Bytes = b"\x80"
  guard b is [u1be(1), ..] else { fail("Bytes") }

  let a : Array[Byte] = [b'\x80']
  guard a is [u1be(1), ..] else { fail("Array[Byte]") }

  let f : FixedArray[Byte] = [b'\x80']
  guard f is [u1be(1), ..] else { fail("FixedArray[Byte]") }

  let r : ReadOnlyArray[Byte] = [b'\x80']
  guard r is [u1be(1), ..] else { fail("ReadOnlyArray[Byte]") }

  let v : ArrayView[Byte] = a[:]
  guard v is [u1be(1), ..] else { fail("ArrayView[Byte]") }

  let mv : MutArrayView[Byte] = a.mut_view()
  guard mv[:] is [u1be(1), ..] else { fail("MutArrayView[Byte]") }
}
```

Signed patterns use two's-complement semantics. For example, `u1be` yields `0`
or `1`, while `i1be` yields `0` or `-1`:

```moonbit
test {
  let bytes = b"\x80"
  let u : UInt = match bytes[:] {
    [u1be(u), ..] => u
    _ => fail("u1be")
  }
  let i : Int = match bytes[:] {
    [i1be(i), ..] => i
    _ => fail("i1be")
  }
  assert_eq(u, 1U)
  assert_eq(i, -1)
}
```

Result types depend on width:

| Width                | Result type    |
|----------------------|----------------|
| 1..32 bits (`u`/`i`) | `UInt` / `Int` |
| 33..64 bits (`u`)    | `UInt64`       |
| 33..64 bits (`i`)    | `Int64`        |

#### Range Pattern

For builtin integer types and `Char`, MoonBit allows matching whether the value falls in a specific range.

Range patterns have the form `a..<b` or `a..=b`, where `..<` means the upper bound is exclusive, and `..=` means inclusive upper bound.
`a` and `b` can be one of:

- literal
- named constant declared with `const`
- `_`, meaning the pattern has no restriction on this side

Here are some examples:

```moonbit
const Zero = 0

fn sign(x : Int) -> Int {
  match x {
    _..<Zero => -1
    Zero => 0
    1..<_ => 1
  }
}

fn classify_char(c : Char) -> String {
  match c {
    'a'..='z' => "lowercase"
    'A'..='Z' => "uppercase"
    '0'..='9' => "digit"
    _ => "other"
  }
}
```

#### Map Pattern

MoonBit allows convenient matching on map-like data structures.
Inside a map pattern, the `key : value` syntax will match if `key` exists in the map, and match the value of `key` with pattern `value`.
The `key? : value` syntax will match no matter `key` exists or not, and `value` will be matched against `map[key]` (an optional).

```moonbit
match map {
  // matches if any only if "b" exists in `map`
  { "b": _, .. } => ...
  // matches if and only if "b" does not exist in `map` and "a" exists in `map`.
  // When matches, bind the value of "a" in `map` to `x`
  { "b"? : None, "a": x, .. } => ...
  // compiler reports missing case: { "b"? : None, "a"? : None }
}
```

- To match a data type `T` using map pattern, `T` must have a method `op_get(Self, K) -> Option[V]` for some type `K` and `V` (see [method and trait](methods.md)).
- Currently, the key part of map pattern must be a literal or constant
- Map patterns are always open: the unmatched keys are silently ignored, and `..` needs to be added to identify this nature
- Map pattern will be compiled to efficient code: every key will be fetched at most once

#### Json Pattern

When the matched value has type `Json`, literal patterns can be used directly, together with constructors:

```moonbit
match json {
  { "version": "1.0.0", "import": [..] as imports, .. } => ...
  { "version": Number(i, ..), "import": Array(imports), .. } => ...
  ...
}
```

#### Guard condition

Each case in a pattern matching expression can have a guard condition. A guard
condition is a boolean expression that must be true for the case to be matched.
If the guard condition is false, the case is skipped and the next case is tried.
For example:

```moonbit
fn guard_cond(x : Int?) -> Int {
  fn f(x : Int) -> Array[Int] {
    [x, x + 42]
  }

  match x {
    Some(a) if f(a) is [0, b] => a + b
    Some(b) => b
    None => -1
  }
}

test {
  assert_eq(guard_cond(None), -1)
  assert_eq(guard_cond(Some(0)), 42)
  assert_eq(guard_cond(Some(1)), 1)
}
```

Note that the guard conditions will not be considered when checking if all
patterns are covered by the match expression. So you will see a warning of
partial match for the following case:

```moonbit
fn guard_check(x : Int?) -> Unit {
  match x {
    Some(a) if a >= 0 => ()
    Some(a) if a < 0 => ()
    None => ()
  }
}
```

##### WARNING
It is not encouraged to call a function that mutates a part of the value being
matched inside a guard condition. When such case happens, the part being mutated
will not be re-evaluated in the subsequent patterns. Use it with caution.
