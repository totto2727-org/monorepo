package main

import (
	"strings"
	"testing"
)

// TestParseHCLBytes (SC-U12): wrapper over Atlas's sqlite.EvalHCLBytes.
func TestParseHCLBytes(t *testing.T) {
	t.Run("valid HCL with one schema and table", func(t *testing.T) {
		const src = `
schema "main" {}

table "user" {
  schema = schema.main
  column "id" {
    type = integer
    null = false
  }
  primary_key {
    columns = [column.id]
  }
}
`
		realm, err := ParseHCLBytes([]byte(src))
		if err != nil {
			t.Fatalf("ParseHCLBytes returned error: %v", err)
		}
		if realm == nil {
			t.Fatal("realm is nil")
		}
		if len(realm.Schemas) != 1 {
			t.Fatalf("len(Schemas) = %d, want 1", len(realm.Schemas))
		}
		if got := realm.Schemas[0].Name; got != "main" {
			t.Errorf("schema name = %q, want \"main\"", got)
		}
		if len(realm.Schemas[0].Tables) != 1 {
			t.Fatalf("len(Tables) = %d, want 1", len(realm.Schemas[0].Tables))
		}
		if got := realm.Schemas[0].Tables[0].Name; got != "user" {
			t.Errorf("table name = %q, want \"user\"", got)
		}
	})

	t.Run("empty input — Atlas yields no schemas", func(t *testing.T) {
		_, err := ParseHCLBytes([]byte(""))
		if err == nil {
			t.Fatal("expected error for empty input, got nil")
		}
		// ParseHCLBytes wraps either the parser error or the
		// "no schemas found" guard — both are acceptable.
	})

	t.Run("malformed HCL", func(t *testing.T) {
		const src = `schema "main" { this is not valid }`
		_, err := ParseHCLBytes([]byte(src))
		if err == nil {
			t.Fatal("expected error for malformed HCL, got nil")
		}
		if !strings.Contains(err.Error(), "sqlite.EvalHCLBytes") {
			t.Errorf("error = %v, expected to wrap sqlite.EvalHCLBytes", err)
		}
	})

	t.Run("HCL with no schema block — guard rejects", func(t *testing.T) {
		// Atlas may parse this without error but realm.Schemas stays empty,
		// so the wrapper's "no schemas found" guard fires.
		const src = `# just a comment, nothing else`
		_, err := ParseHCLBytes([]byte(src))
		if err == nil {
			t.Fatal("expected error for schema-less HCL, got nil")
		}
	})
}
