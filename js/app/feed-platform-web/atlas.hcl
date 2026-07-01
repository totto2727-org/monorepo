env "local" {
  src = "file://db/schema.hcl"
  url = "sqlite://node_modules/.cache/db"
  dev = "sqlite://file?mode=memory"
}
