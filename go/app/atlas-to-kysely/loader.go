// Package hclloader parses Atlas schema.hcl files using the official
// ariga.io/atlas SQLite codec — no database connection required.
package main

import (
	"fmt"

	"ariga.io/atlas/sql/schema"
	"ariga.io/atlas/sql/sqlite"
)

// ParseHCLBytes parses an Atlas schema.hcl file from raw bytes and returns
// a *schema.Realm containing all schemas and their tables.
//
// Uses sqlite.EvalHCLBytes which evaluates the HCL expression types
// (int, text, boolean, enum(...), etc.) correctly without a DB connection.
func ParseHCLBytes(src []byte) (*schema.Realm, error) {
	var realm schema.Realm
	if err := sqlite.EvalHCLBytes(src, &realm, nil); err != nil {
		return nil, fmt.Errorf("sqlite.EvalHCLBytes: %w", err)
	}
	if len(realm.Schemas) == 0 {
		return nil, fmt.Errorf("no schemas found in HCL")
	}
	return &realm, nil
}
