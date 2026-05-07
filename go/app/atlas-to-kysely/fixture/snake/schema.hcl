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

table "session" {
  schema = schema.main

  column "id" {
    type = text
    null = false
  }
  column "user_id" {
    type = text
    null = false
  }
  column "token" {
    type = text
    null = false
  }
  column "expires_at" {
    type = text
    null = false
  }
  column "ip_address" {
    type = text
    null = true
  }
  column "user_agent" {
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

  foreign_key "session_user_id_fk" {
    columns     = [column.user_id]
    ref_columns = [table.user.column.id]
    on_delete   = CASCADE
  }
}

table "account" {
  schema = schema.main

  column "id" {
    type = text
    null = false
  }
  column "user_id" {
    type = text
    null = false
  }
  column "account_id" {
    type = text
    null = false
  }
  column "provider_id" {
    type = text
    null = false
  }
  column "access_token" {
    type = text
    null = true
  }
  column "refresh_token" {
    type = text
    null = true
  }
  column "access_token_expires_at" {
    type = text
    null = true
  }
  column "refresh_token_expires_at" {
    type = text
    null = true
  }
  column "scope" {
    type = text
    null = true
  }
  column "id_token" {
    type = text
    null = true
  }
  column "password" {
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

  foreign_key "account_user_id_fk" {
    columns     = [column.user_id]
    ref_columns = [table.user.column.id]
    on_delete   = CASCADE
  }
}

table "verification" {
  schema = schema.main

  column "id" {
    type = text
    null = false
  }
  column "identifier" {
    type = text
    null = false
  }
  column "value" {
    type = text
    null = false
  }
  column "expires_at" {
    type = text
    null = false
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
