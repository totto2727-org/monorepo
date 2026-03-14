variable "database_url" {
  type    = string
  default = getenv("DATABASE_URL")
}

variable "database_auth_token" {
  type    = string
  default = getenv("DATABASE_AUTH_TOKEN")
}

env "local" {
  src     = "file://db/schema.hcl"
  url     = "sqlite://node_modules/.cache/db"
  dev     = "sqlite://file?mode=memory"
  migration {
    dir = "file://db/migrations"
  }
}

env "turso" {
  src     = "file://db/schema.hcl"
  url     = "${var.database_url}?authToken=${var.database_auth_token}"
  dev     = "sqlite://file?mode=memory"
  migration {
    dir = "file://db/migrations"
  }
}
