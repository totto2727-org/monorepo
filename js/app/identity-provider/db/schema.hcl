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

  index "user_email_unique" {
    unique  = true
    columns = [column.email]
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

  index "session_token_unique" {
    unique  = true
    columns = [column.token]
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

table "passkey" {
  schema = schema.main

  column "id" {
    type = text
    null = false
  }
  column "name" {
    type = text
    null = true
  }
  column "public_key" {
    type = text
    null = false
  }
  column "user_id" {
    type = text
    null = false
  }
  column "credential_id" {
    type = text
    null = false
  }
  column "counter" {
    type = integer
    null = false
  }
  column "device_type" {
    type = text
    null = false
  }
  column "backed_up" {
    type = integer
    null = false
  }
  column "transports" {
    type = text
    null = true
  }
  column "aaguid" {
    type = text
    null = true
  }
  column "created_at" {
    type = text
    null = false
  }
  primary_key {
    columns = [column.id]
  }

  index "passkey_credential_id_index" {
    columns = [column.credential_id]
  }

  index "passkey_user_id_index" {
    columns = [column.user_id]
  }

  foreign_key "passkey_user_id_fk" {
    columns     = [column.user_id]
    ref_columns = [table.user.column.id]
    on_delete   = CASCADE
  }
}

table "jwks" {
  schema = schema.main

  column "id" {
    type = text
    null = false
  }
  column "public_key" {
    type = text
    null = false
  }
  column "private_key" {
    type = text
    null = false
  }
  column "created_at" {
    type = text
    null = false
  }
  column "expires_at" {
    type = text
    null = true
  }

  primary_key {
    columns = [column.id]
  }
}

table "oauth_application" {
  schema = schema.main

  column "id" {
    type = text
    null = false
  }
  column "name" {
    type = text
    null = true
  }
  column "client_id" {
    type = text
    null = false
  }
  column "client_secret" {
    type = text
    null = true
  }
  column "disabled" {
    type = integer
    null = true
  }
  column "skip_consent" {
    type = integer
    null = true
  }
  column "enable_end_session" {
    type = integer
    null = true
  }
  column "subject_type" {
    type = text
    null = true
  }
  column "scopes" {
    type = text
    null = true
  }
  column "redirect_uris" {
    type = text
    null = false
  }
  column "uri" {
    type = text
    null = true
  }
  column "icon" {
    type = text
    null = true
  }
  column "contacts" {
    type = text
    null = true
  }
  column "tos" {
    type = text
    null = true
  }
  column "policy" {
    type = text
    null = true
  }
  column "software_id" {
    type = text
    null = true
  }
  column "software_version" {
    type = text
    null = true
  }
  column "software_statement" {
    type = text
    null = true
  }
  column "post_logout_redirect_uris" {
    type = text
    null = true
  }
  column "token_endpoint_auth_method" {
    type = text
    null = true
  }
  column "grant_types" {
    type = text
    null = true
  }
  column "response_types" {
    type = text
    null = true
  }
  column "public" {
    type = integer
    null = true
  }
  column "type" {
    type = text
    null = true
  }
  column "require_pkce" {
    type = integer
    null = true
  }
  column "reference_id" {
    type = text
    null = true
  }
  column "metadata" {
    type = text
    null = true
  }
  column "user_id" {
    type = text
    null = true
  }
  column "created_at" {
    type = text
    null = true
  }
  column "updated_at" {
    type = text
    null = true
  }

  primary_key {
    columns = [column.id]
  }

  index "oauth_application_client_id_unique" {
    unique  = true
    columns = [column.client_id]
  }

  foreign_key "oauth_application_user_id_fk" {
    columns     = [column.user_id]
    ref_columns = [table.user.column.id]
    on_delete   = SET_NULL
  }
}

table "oauth_access_token" {
  schema = schema.main

  column "id" {
    type = text
    null = false
  }
  column "access_token" {
    type = text
    null = false
  }
  column "client_id" {
    type = text
    null = false
  }
  column "session_id" {
    type = text
    null = true
  }
  column "user_id" {
    type = text
    null = true
  }
  column "scope" {
    type = text
    null = false
  }
  column "reference_id" {
    type = text
    null = true
  }
  column "refresh_id" {
    type = text
    null = true
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
    null = true
  }

  primary_key {
    columns = [column.id]
  }

  index "oauth_access_token_access_token_unique" {
    unique  = true
    columns = [column.access_token]
  }

  index "oauth_access_token_client_id_index" {
    columns = [column.client_id]
  }

  index "oauth_access_token_session_id_index" {
    columns = [column.session_id]
  }

  index "oauth_access_token_user_id_index" {
    columns = [column.user_id]
  }

  index "oauth_access_token_refresh_id_index" {
    columns = [column.refresh_id]
  }

  foreign_key "oauth_access_token_client_id_fk" {
    columns     = [column.client_id]
    ref_columns = [table.oauth_application.column.client_id]
    on_delete   = CASCADE
  }

  foreign_key "oauth_access_token_session_id_fk" {
    columns     = [column.session_id]
    ref_columns = [table.session.column.id]
    on_delete   = SET_NULL
  }

  foreign_key "oauth_access_token_user_id_fk" {
    columns     = [column.user_id]
    ref_columns = [table.user.column.id]
    on_delete   = SET_NULL
  }

  foreign_key "oauth_access_token_refresh_id_fk" {
    columns     = [column.refresh_id]
    ref_columns = [table.oauth_refresh_token.column.id]
    on_delete   = SET_NULL
  }
}

table "oauth_refresh_token" {
  schema = schema.main

  column "id" {
    type = text
    null = false
  }
  column "token" {
    type = text
    null = false
  }
  column "client_id" {
    type = text
    null = false
  }
  column "session_id" {
    type = text
    null = true
  }
  column "user_id" {
    type = text
    null = false
  }
  column "reference_id" {
    type = text
    null = true
  }
  column "expires_at" {
    type = text
    null = false
  }
  column "created_at" {
    type = text
    null = false
  }
  column "revoked" {
    type = text
    null = true
  }
  column "auth_time" {
    type = text
    null = true
  }
  column "scope" {
    type = text
    null = false
  }

  primary_key {
    columns = [column.id]
  }

  index "oauth_refresh_token_token_unique" {
    unique  = true
    columns = [column.token]
  }

  index "oauth_refresh_token_client_id_index" {
    columns = [column.client_id]
  }

  index "oauth_refresh_token_session_id_index" {
    columns = [column.session_id]
  }

  index "oauth_refresh_token_user_id_index" {
    columns = [column.user_id]
  }

  foreign_key "oauth_refresh_token_client_id_fk" {
    columns     = [column.client_id]
    ref_columns = [table.oauth_application.column.client_id]
    on_delete   = CASCADE
  }

  foreign_key "oauth_refresh_token_session_id_fk" {
    columns     = [column.session_id]
    ref_columns = [table.session.column.id]
    on_delete   = SET_NULL
  }

  foreign_key "oauth_refresh_token_user_id_fk" {
    columns     = [column.user_id]
    ref_columns = [table.user.column.id]
    on_delete   = CASCADE
  }
}

table "oauth_consent" {
  schema = schema.main

  column "id" {
    type = text
    null = false
  }
  column "user_id" {
    type = text
    null = true
  }
  column "client_id" {
    type = text
    null = false
  }
  column "scope" {
    type = text
    null = false
  }
  column "reference_id" {
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

  index "oauth_consent_client_id_index" {
    columns = [column.client_id]
  }

  index "oauth_consent_user_id_index" {
    columns = [column.user_id]
  }

  foreign_key "oauth_consent_client_id_fk" {
    columns     = [column.client_id]
    ref_columns = [table.oauth_application.column.client_id]
    on_delete   = CASCADE
  }

  foreign_key "oauth_consent_user_id_fk" {
    columns     = [column.user_id]
    ref_columns = [table.user.column.id]
    on_delete   = SET_NULL
  }
}
