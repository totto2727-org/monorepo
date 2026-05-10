schema "main" {
}

table "user_account" {
  schema = schema.main

  column "id" {
    type           = integer
    null           = false
    auto_increment = true
  }
  column "user_name" {
    type = text
    null = false
  }
  column "display_name" {
    type = text
    null = true
  }
  column "STATUS" {
    type    = text
    null    = false
    default = "active"
  }
  column "score" {
    type = real
    null = true
  }
  column "is_active" {
    type = boolean
    null = false
  }
  column "metadata" {
    type = json
    null = true
  }
  column "avatar" {
    type = blob
    null = true
  }
  column "created_at" {
    type    = text
    null    = false
    default = "CURRENT_TIMESTAMP"
  }

  primary_key {
    columns = [column.id]
  }
}

table "tag" {
  schema = schema.main

  column "id" {
    type           = integer
    null           = false
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

# Identifiers already in camelCase. Both modes must leave them untouched
# (camel = idempotent transform, snake = identity passthrough).
table "productImage" {
  schema = schema.main

  column "id" {
    type           = integer
    null           = false
    auto_increment = true
  }
  column "productId" {
    type = integer
    null = false
  }
  column "imageUrl" {
    type = text
    null = false
  }
  column "altText" {
    type = text
    null = true
  }

  primary_key {
    columns = [column.id]
  }
}
