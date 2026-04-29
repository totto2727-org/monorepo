schema "main" {
}

table "all_types" {
  schema = schema.main

  column "col_blob" {
    type = blob
    null = false
  }
  column "col_bool" {
    type = boolean
    null = false
  }
  column "col_int" {
    type = integer
    null = false
  }
  column "col_json" {
    type = json
    null = false
  }
  column "col_nullable_blob" {
    type = blob
    null = true
  }
  column "col_nullable_bool" {
    type = boolean
    null = true
  }
  column "col_nullable_int" {
    type = integer
    null = true
  }
  column "col_nullable_real" {
    type = real
    null = true
  }
  column "col_nullable_text" {
    type = text
    null = true
  }
  column "col_real" {
    type = real
    null = false
  }
  column "col_text" {
    type = text
    null = false
  }
}
