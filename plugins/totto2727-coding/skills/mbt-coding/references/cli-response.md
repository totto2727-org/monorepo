# MoonBit CLI Response

> Document type: concrete MoonBit CLI implementation guidance.

## JSON responses

Treat JSON responses as JSON responses by default: print or write the response body unchanged when no internal decision depends on its fields.

Only parse JSON when the command needs to inspect it. When parsing is required:

1. parse at the smallest possible scope
2. immediately convert into a command-specific typed struct/enum
3. continue with that typed value
4. do not let raw `Json` leak through the rest of the command

The conversion style should mirror options conversion: raw input at the boundary, typed value inside the implementation.
