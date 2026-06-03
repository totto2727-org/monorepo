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

table "oauth_refresh_session" {
  schema = schema.main

  column "session_token" {
    type = text
    null = false
  }
  column "refresh_token" {
    type = text
    null = false
  }
  column "access_token" {
    type = text
    null = false
  }
  column "expires_at" {
    type = integer
    null = false
  }

  primary_key {
    columns = [column.session_token]
  }
}
