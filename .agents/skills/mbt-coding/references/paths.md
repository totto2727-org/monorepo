# MoonBit Paths

> Document type: concrete MoonBit implementation guidance.

Keep path values as `@path.Path` across library and application layers. Accept and return `Path` values when the operation is about filesystem locations; convert to text only at an external boundary that requires text.

For paths, use `@path.Path::join` instead of joining strings by hand. For paths with more than two segments, write the construction as a pipeline so each segment is visible and ordered:

```mbt check
let skill_dir = root
  |> @path.Path::join(".agents")
  |> @path.Path::join("skills")
  |> @path.Path::join(skill_name)
```
