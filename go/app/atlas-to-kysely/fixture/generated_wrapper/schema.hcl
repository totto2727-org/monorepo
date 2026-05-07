schema "main" {
}

table "post" {
  schema = schema.main

  column "id" {
    type = integer
    null = false
    auto_increment = true
  }
  column "title" {
    type = text
    null = false
  }
  column "body" {
    type = text
    null = true
  }
  column "status" {
    type = text
    null = false
    default = "draft"
  }
  column "view_count" {
    type = integer
    null = false
    default = 0
  }
  column "created_at" {
    type = text
    null = false
    default = "CURRENT_TIMESTAMP"
  }

  primary_key {
    columns = [column.id]
  }
}

table "tag" {
  schema = schema.main

  column "id" {
    type = integer
    null = false
    auto_increment = true
  }
  column "name" {
    type = text
    null = false
  }

  primary_key {
    columns = [column.id]
  }
}
