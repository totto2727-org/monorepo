schema "main" {
}

table "users" {
  schema = schema.main
  column "id" {
    type = int
  }
  column "name" {
    type = text(255)
  }
  column "manager_id" {
    type = int
  }
  primary_key {
    columns = [
      column.id
    ]
  }
  index "idx_name" {
    columns = [
      column.name
    ]
    unique = true
  }
  foreign_key "manager_fk" {
    columns = [column.manager_id]
    ref_columns = [column.id]
  }
}
