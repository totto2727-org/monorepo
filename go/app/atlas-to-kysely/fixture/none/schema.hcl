schema "main" {
}

table "user" {
  schema = schema.main

  column "id" {
    type = text
    null = false
  }
  column "name" {
    type = text
    null = false
  }
  column "email" {
    type = text
    null = false
  }
  column "email_verified" {
    type = integer
    null = false
  }
  column "image" {
    type = text
    null = true
  }
  column "created_at" {
    type = text
    null = false
  }
  column "updated_at" {
    type = text
    null = false
  }

  primary_key {
    columns = [column.id]
  }
}
