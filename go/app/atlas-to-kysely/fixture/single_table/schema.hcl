schema "main" {
}

table "minimal" {
  schema = schema.main

  column "id" {
    type = integer
    null = false
  }
}
