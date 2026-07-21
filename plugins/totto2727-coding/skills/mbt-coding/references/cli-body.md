# MoonBit CLI Body

> Document type: concrete MoonBit CLI implementation guidance.

## Body struct conversion

The body struct represents the request payload shape. Convert options into the body after option validation. Domain processing required to build the payload, such as reading an HTML file into an `html` body field, belongs here or in the command runner immediately before this conversion, not in options parsing.

```moonbit
///|
struct ScreenshotBody {
  url : String?
  html : String?
}

///|
async fn ScreenshotBody::from_options(options : ScreenshotOptions) -> ScreenshotBody {
  match options.input {
    Url(value) => { url: Some(value), html: None }
    HtmlFile(path) => { url: None, html: Some(@fs.read_file(path).text()) }
  }
}
```

Keep body conversion command-specific. Avoid generic `build_body`, `add_bool_nested`, `add_string_nested`, or “JSON patch” helpers.
