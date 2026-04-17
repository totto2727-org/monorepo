<!-- Derived from MoonBit documentation by moonbitlang -->
<!-- https://github.com/moonbitlang/moonbit-docs -->
<!-- Prose content (post July 4, 2024): CC BY-SA 4.0 -->
<!-- Code examples: Apache 2.0 -->
<!-- Modifications: Extracted and reformatted as Claude Code skill files -->

### Special Syntax

#### Pipelines

MoonBit provides a convenient pipe syntax `x |> f(y)`, which can be used to chain regular function calls:

```moonbit
5 |> ignore // <=> ignore(5)
[] |> Array::push(5) // <=> Array::push([], 5)
1
|> add(5) // <=> add(1, 5)
|> x => { x + 1 }
|> ignore // <=> ignore(add(1, 5))
```

The MoonBit code follows the _data-first_ style, meaning the function places its "subject" as the first argument.
Thus, the pipe operator inserts the left-hand side value into the first argument of the right-hand side function call by default.
For example, `x |> f(y)` is equivalent to `f(x, y)`.

You can use the `_` operator to insert `x` into any argument of the function `f`, such as `x |> f(y, _)`, which is equivalent to `f(y, x)`. Labeled arguments are also supported.

The pipe operator can also connect to an arrow function. When piping into an arrow function, the function body must be wrapped in curly braces, for example `value |> x => { x + 1 }`.

#### Cascade Operator

The cascade operator `..` is used to perform a series of mutable operations on
the same value consecutively. The syntax is as follows:

```moonbit
let arr = []..append([1])
```

Here, `x..f()` is equivalent to `{ x.f(); x }`.

Consider the following scenario: for a `StringBuilder` type that has methods
like `write_string`, `write_char`, `write_object`, etc., we often need to perform
a series of operations on the same `StringBuilder` value:

```moonbit
let builder = StringBuilder::new()
builder.write_char('a')
builder.write_char('a')
builder.write_object(1001)
builder.write_string("abcdef")
let result = builder.to_string()
```

To avoid repetitive typing of `builder`, its methods are often designed to
return `self` itself, allowing operations to be chained using the `.` operator.
To distinguish between immutable and mutable operations, in MoonBit,
for all methods that return `Unit`, cascade operator can be used for
consecutive operations without the need to modify the return type of the methods.

```moonbit
let result = StringBuilder::new()
  ..write_char('a')
  ..write_char('a')
  ..write_object(1001)
  ..write_string("abcdef")
  .to_string()
```

#### is Expression

The `is` expression tests whether a value conforms to a specific pattern. It
returns a `Bool` value and can be used anywhere a boolean value is expected,
for example:

```moonbit
fn[T] is_none(x : T?) -> Bool {
  x is None
}

fn start_with_lower_letter(s : String) -> Bool {
  s is ['a'..='z', ..]
}
```

Pattern binders introduced by `is` expressions can be used in the following
contexts:

1. In boolean AND expressions (`&&`):
   binders introduced in the left-hand expression can be used in the right-hand
   expression
   ```moonbit
   fn f(x : Int?) -> Bool {
     x is Some(v) && v >= 0
   }
   ```
2. In the first branch of `if` expression: if the condition is a sequence of
   boolean expressions `e1 && e2 && ...`, the binders introduced by the `is`
   expression can be used in the branch where the condition evaluates to `true`.
   ```moonbit
   fn g(x : Array[Int?]) -> Unit {
     if x is [v, .. rest] && v is Some(i) && i is (0..=10) {
       println(v)
       println(i)
       println(rest)
     }
   }
   ```
3. In the following statements of a `guard` condition:
   ```moonbit
   fn h(x : Int?) -> Unit {
     guard x is Some(v)
     println(v)
   }
   ```
4. In the body of a `while` loop:
   ```moonbit
   fn i(x : Int?) -> Unit {
     let mut m = x
     while m is Some(v) {
       println(v)
       m = None
     }
   }
   ```

Note that `is` expression can only take a simple pattern. If you need to use
`as` to bind the pattern to a variable, you have to add parentheses. For
example:

```moonbit
fn j(x : Int) -> Int? {
  Some(x)
}

fn init {
  guard j(42) is (Some(a) as b)
  println(a)
  println(b)
}
```

#### Lexmatch

`lexmatch` matches a `String` against a regex pattern and lets you bind the
pieces of a match. The search-mode pattern is `(before, regex pieces, after)`,
where `before` and `after` are optional bindings for the unmatched prefix and
suffix, separated by commas. The regex pieces in the middle are separated by
whitespace only. The regex itself is written as a sequence of string literals,
so you can split it across lines or insert comments between parts. You can
also bind a matched sub-pattern using `as`, such as `("b*" as b)`.

`lexmatch?` is a boolean check similar to `is`, and it can introduce binders
for use in the same contexts as `is` expressions.

`lexmatch` also supports a lexer-style mode: `lexmatch <expr> with longest`,
which picks the longest match among alternatives (for example, `if|[a-z]*`
matches `iff` as `iff` in longest mode, while search mode matches `if` first).

Regex literals do not support `\\b`, `\\s`, or `\\w`. Use POSIX character
classes like `[:digit:]` inside ranges (for example, `[[:digit:]]`).

```moonbit
test {
  let text = "xxabbbcyy"
  lexmatch text {
    (before, "a" ("b*" as b) "c", after) => {
      inspect(before, content="xx")
      inspect(b, content="bbb")
      inspect(after, content="yy")
    }
    _ => fail("")
  }

  if text lexmatch? ("a" ("b*" as b) "c") && b.length() > 0 {
    inspect(b, content="bbb")
  }

  let keyword = "iff"
  lexmatch keyword with longest {
    ("if|[a-z]*" as ident) => inspect(ident, content="iff")
    _ => fail("")
  }
}
```

#### Spread Operator

MoonBit provides a spread operator to expand a sequence of elements when
constructing `Array`, `String`, and `Bytes` using the array literal syntax. To
expand such a sequence, it needs to be prefixed with `..`, and it must have
`iter()` method that yields the corresponding type of element.

For example, we can use the spread operator to construct an array:

```moonbit
test {
  let a1 : Array[Int] = [1, 2, 3]
  let a2 : FixedArray[Int] = [4, 5, 6]
  let a3 : @list.List[Int] = @list.from_array([7, 8, 9])
  let a : Array[Int] = [..a1, ..a2, ..a3, 10]
  inspect(a, content="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]")
}
```

Similarly, we can use the spread operator to construct a string:

```moonbit
test {
  let s1 : String = "Hello"
  let s2 : StringView = "World".view()
  let s3 : Array[Char] = [..s1, ' ', ..s2, '!']
  let s : String = [..s1, ' ', ..s2, '!', ..s3]
  inspect(s, content="Hello World!Hello World!")
}
```

The last example shows how the spread operator can be used to construct a bytes
sequence.

```moonbit
test {
  let b1 : Bytes = "hello"
  let b2 : BytesView = b1[1:4]
  let b : Bytes = [..b1, ..b2, 10]
  inspect(
    b,
    content=(
      #|b"helloell\x0a"
    ),
  )
}
```

#### TODO syntax

The `todo` syntax (`...`) is a special construct used to mark sections of code that are not yet implemented or are placeholders for future functionality. For example:

```moonbit
fn todo_in_func() -> Int {
  ...
}
```
