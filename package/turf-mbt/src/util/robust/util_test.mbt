///|
fn parse_fixture_lines(content : String) -> Array[Array[Double]] {
  let results : Array[Array[Double]] = []
  let lines = content.split("\n")
  for line in lines {
    let trimmed = line.trim()
    if trimmed == "" {
      continue
    }
    let parts = trimmed.split(" ").filter(fn(s) { s != "" }).collect()
    if parts.length() < 2 {
      continue
    }
    let values : Array[Double] = []
    for i = 1; i < parts.length(); i = i + 1 {
      values.push(@strconv.parse_double(parts[i])) catch {
        _ => break
      }
    }
    if values.length() > 0 {
      results.push(values)
    }
  }
  results
}

///|
fn signum(x : Double) -> Double {
  if x > 0.0 {
    1.0
  } else if x < 0.0 {
    -1.0
  } else {
    0.0
  }
}
