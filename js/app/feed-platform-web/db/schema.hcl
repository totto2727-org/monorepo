schema "main" {
}

table "oauth_nonce" {
  schema = schema.main

  column "state" {
    type = text
    null = false
  }
  column "nonce" {
    type = text
    null = false
  }
  column "expires_at" {
    type = integer
    null = false
  }

  primary_key {
    columns = [column.state]
  }
}
