schema "main" {
}

table "item" {
  schema = schema.main

  column "default_not_null" {
    type = text
    null = false
    default = "hello"
  }
  column "default_nullable" {
    type = text
    null = true
    default = "unknown"
  }
  column "plain" {
    type = text
    null = false
  }
  column "plain_nullable" {
    type = text
    null = true
  }
}
