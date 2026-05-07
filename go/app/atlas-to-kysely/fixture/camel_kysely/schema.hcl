schema "main" {
}

table "app_config" {
  schema = schema.main

  column "ID" {
    type = integer
    null = false
  }
  column "USER_ID" {
    type = text
    null = false
  }
  column "HTTP_STATUS" {
    type = integer
    null = false
  }
  column "api_key" {
    type = text
    null = true
  }
  column "created_at" {
    type = text
    null = false
  }
  column "UPDATED_AT" {
    type = text
    null = false
  }
  column "is_active" {
    type = integer
    null = false
  }
  column "MAX_RETRY_COUNT" {
    type = integer
    null = false
  }

  primary_key {
    columns = [column.ID]
  }
}
