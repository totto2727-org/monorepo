variable "local_database_url" {
  type    = string
  default = getenv("LOCAL_DATABASE_URL")
}

variable "database_url" {
  type    = string
  default = getenv("DATABASE_URL")
}

variable "database_auth_token" {
  type    = string
  default = getenv("DATABASE_AUTH_TOKEN")
}

env "local" {
  src = "file://db/schema.hcl"
  url = "sqlite://${var.local_database_url}"
  dev = "sqlite://file?mode=memory"
  migration {
    dir = "file://db/migrations"
  }
}

env "production" {
  src     = "file://db/schema.hcl"
  url     = "${var.database_url}?authToken=${var.database_auth_token}"
  dev     = "sqlite://file?mode=memory"
  exclude = ["_litestream*"]
}
