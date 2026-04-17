<!-- Derived from MoonBit documentation by moonbitlang -->
<!-- https://github.com/moonbitlang/moonbit-docs -->
<!-- Prose content (post July 4, 2024): CC BY-SA 4.0 -->
<!-- Code examples: Apache 2.0 -->
<!-- Modifications: Extracted and reformatted as Claude Code skill files -->

### Special Syntax

#### Pipelines

MoonBit provides convenient pipe syntaxes `x |> f(y)` and `f <| x`, which can be used to chain regular function calls or make nested builder-style code easier to read:

```moonbit
5 |> ignore // <=> ignore(5)
[] |> Array::push(5) // <=> Array::push([], 5)
1
|> add(5) // <=> add(1, 5)
|> x => { x + 1 }
|> ignore // <=> ignore(add(1, 5))
```

The MoonBit code follows the *data-first* style, meaning the function places its "subject" as the first argument.
Thus, the pipe operator inserts the left-hand side value into the first argument of the right-hand side function call by default.
For example, `x |> f(y)` is equivalent to `f(x, y)`.

You can use the `_` operator to insert `x` into any argument of the function `f`, such as `x |> f(y, _)`, which is equivalent to `f(y, x)`. Labeled arguments are also supported.

The pipe operator can also connect to an arrow function. When piping into an arrow function, the function body must be wrapped in curly braces, for example `value |> x => { x + 1 }`.

The reverse pipe operator applies the right-hand side as the final argument of the left-hand side call. For example, `f <| x` is equivalent to `f(x)`, and `f(a, b) <| c` is equivalent to `f(a, b, c)`. This is especially useful for DSL-like code, since nested calls such as `div([text("hello")])` can instead be written as `div <| [text <| "hello"]`.

```moonbit
let page = div <| [
    text <| "hello",
    section("toolbar") <| fn() { [text <| "save", text <| "cancel"] },
  ]
inspect(
  page,
  content="div(text(hello), toolbar: div(text(save), text(cancel)))",
)
```

Because reverse pipe attaches the final argument, it also works well with functions whose last argument is a lambda, enabling a trailing-lambda style such as `section("toolbar") <| fn () { ... }`.

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

#### Regex Literal Expression

`re"..."` is a regex literal expression. Its type is `Regex`.

Regex literals are ordinary expressions, so they can be stored in local
bindings, passed as arguments, used as default argument values, and defined as
constants:

```moonbit
let r : Regex = re"a(b+)"
const IDENT_START : Regex = re"[A-Za-z_]"
const IDENT : Regex = IDENT_START + re"[A-Za-z0-9_]*"
```

Regex values can also be combined with `+` for sequence and `|` for
alternation. In places that require a regex constant expression, such as
[`=~`](), named `const` values defined from regex
literals can be referenced directly.

Unlike ordinary string literals, regex literals do not require double-escaping
backslashes. For example, write `re"/\*"` instead of `re"/\\*"`.

```moonbit
const REGEX_IDENT_START = re"[A-Za-z_]"

const REGEX_IDENT_CONT = re"[A-Za-z0-9_]*"

const REGEX_AB : Regex = re"a" + re"b"

fn regex_default_arg(re? : Regex = re"abc") -> Bool {
  re.execute("zabc") is Some(_)
}

test {
  let regex : Regex = re"a(b+)"
  assert_true(regex.execute("abbb") is Some(_))
  assert_true(regex.execute("ac") is None)

  assert_true(REGEX_AB.execute("ab") is Some(_))
  assert_true(REGEX_AB.execute("ac") is None)
  assert_true(regex_default_arg())
}
```

Invalid regex literals are rejected at compile time.

Regex literals use MoonBit's regex syntax. The supported forms include:

- Literal characters: ordinary characters match themselves
- Wildcard: `.` matches any single character, including newline
- Character classes: `[abc]`, `[^abc]`, `[a-z]`
- POSIX classes inside character classes: `[[:digit:]]`, `[[:alpha:]]`,
  `[[:space:]]`, `[[:word:]]`, `[[:xdigit:]]`, etc.
- Quantifiers: `*`, `+`, `?`, `{n}`, `{n,}`, `{n,m}`
- Non-greedy quantifiers: `*?`, `+?`, `??`, `{n}?`, `{n,}?`, `{n,m}?`
- Grouping and alternation: `( ... )`, `(?: ... )`, `(?<name> ... )`, `a|b`
- Assertions: `^`, `$`, `\b`, `\B`
- Scoped modifier: `(?i: ... )` for case-insensitive matching

Escape handling is regex-oriented rather than string-oriented. Common escapes
include `\n`, `\r`, `\t`, `\f`, `\v`, escaped metacharacters such as `\.` and
`\(`, and Unicode escapes `\uXXXX` / `\u{X...}`. To match a literal `{`, use
`[{]` rather than `\{`. This leaves room for future interpolation support in
regex literals, where `\{` would conflict with the interpolation syntax.

There are several important semantics and restrictions:

- `^` and `$` are non-multiline anchors: they match only the beginning and end
  of the whole input
- `\b` and `\B` are currently usable when a regex literal is handled as a
  first-class `Regex` value
  They are not currently available in `regex match expression` constant
  contexts such as [`=~`](), but this restriction is
  expected to be relaxed in the future
- POSIX character classes are ASCII-based
- `\d`, `\D`, `\s`, `\S`, `\w`, and `\W` are not supported
  Use `[[:digit:]]`, `[^[:digit:]]`, `[[:space:]]`, `[^[:space:]]`,
  `[[:word:]]`, and `[^[:word:]]` instead
- `\xHH` byte escapes are not supported in `re"..."`; use Unicode escapes or
  ordinary characters instead
- Lookahead, lookbehind, backreferences, and character-class set operations are
  not supported
- In character classes, `-` is used for ranges
  To match a literal dash, escape it as `\-`; putting `-` at the start or end
  of a character class is not supported

Named capture groups such as `(?<id>[0-9]+)` belong to the `Regex` value
itself. They are useful with APIs such as `Regex::execute` and
`MatchResult::named_group`, but they do not introduce MoonBit binders by
themselves.

When a regex literal is used as a first-class `Regex` value, operations such
as `Regex::execute` use first-match semantics: they return the first match
found from the search position. They do not provide a longest-match mode.

#### Regex Match Expression

Regex match expressions use the `=~` operator to search a `StringView` with a
regex constant expression. This is a newer regex-matching form intended to
replace experimental `lexmatch`. The expression returns `Bool`.

```moonbit
input =~ re"abc"
input =~ ((PREFIX + SUFFIX) as whole, before=head, after=tail)
input =~ (re"b", before~, after~)
```

The right-hand side must be a regex constant expression: a regex literal such
as `re"abc"`, a named `const`, or an expression built from constants with `+`
(concatenation), `|` (alternation), and parentheses. Arbitrary runtime values
are not allowed.

Use `as` to bind the matched substring. Use `before` and `after` to bind the
unmatched prefix and suffix as `StringView`; `before~` and `after~` are
shorthand forms that bind variables named `before` and `after`.

This is separate from regex named capture groups. For example, in
`re"(?<id>[0-9]+)"`, the name `id` is part of the regex engine's capture
metadata, not a MoonBit binder. If you need a binder in `=~`, use `as`, such
as `(re"(?<id>[0-9]+)" as digits)`.

Like `is`, binders introduced by `=~` can be used in the same boolean-flow
contexts, such as the right-hand side of `&&` and the true branch of `if`.
Regex matching is search-based by default, so `"zabc!" =~ re"abc"` is `true`.
Use anchors such as `^` and `$` when you need to constrain the match to the
beginning or end of the input.

`=~` also uses first-match semantics. It will not support longest-match
behavior.

```moonbit
test {
  let input = " let_name = 42 "
  if (input =~ (
      (REGEX_IDENT_START + REGEX_IDENT_CONT) as ident,
      before=head,
      after=tail
    )) {
    assert_true(head is " ")
    assert_true(ident is "let_name")
    assert_true(tail is " = 42 ")
  } else {
    fail("expected identifier")
  }

  if ("abc" =~ (re"b", before~, after~)) {
    assert_true(before is "a")
    assert_true(after is "c")
  } else {
    fail("expected middle match")
  }

  let source : StringView = "abc"
  if (source =~ (re"." as ch, after=rest)) {
    assert_eq(ch, 'a')
    assert_true(rest is "bc")
  } else {
    fail("expected leading char")
  }

  assert_true("zabc!" =~ re"abc")
  assert_true(!("zabc!" =~ re"^abc"))
}
```

In the example above, `head`, `ident`, `tail`, `before`, `after`, and `rest`
have type `StringView`. The binder `ch` has type `Char`, because `re"."`
matches exactly one character.

#### Lexmatch

##### WARNING
`lexmatch` and `lexmatch?` are deprecated. Prefer
[regex match expression]() in new code.
This section is kept as reference for existing code.

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

Regex literals support `\b` and `\B` as part of the regex syntax, but these
word-boundary assertions are not currently available in `regex match expression` constant contexts. They do work when the regex is used as a
first-class `Regex` value, and this restriction is expected to be relaxed in
the future. Regex literals also do not support `\d`, `\D`, `\s`, `\S`, `\w`,
or `\W`. Use POSIX character classes like `[[:digit:]]` inside character
classes instead.

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
