package main

import (
	"fmt"
	"strings"

	"ariga.io/atlas/sql/schema"
	"ariga.io/atlas/sql/sqlite"
)

// tsType holds the TypeScript type representation for a single column.
type tsType struct {
	// base is the raw TS type before nullability (e.g. "number", "string")
	base string
	// nullable wraps base as `base | null`
	nullable bool
	// generated wraps the type as `Generated<T>` for auto_increment/default columns
	generated bool
}

func (t tsType) innerType() string {
	inner := t.base
	if t.nullable {
		inner = fmt.Sprintf("%s | null", inner)
	}
	if t.generated {
		return fmt.Sprintf("Generated<%s>", inner)
	}
	return inner
}

// columnToTsType converts an Atlas schema.Column to a tsType.
func columnToTsType(col *schema.Column) tsType {
	base := schemaTypeToBase(col.Type.Type)
	nullable := col.Type.Null
	generated := isGenerated(col)

	return tsType{base: base, nullable: nullable, generated: generated}
}

// isGenerated returns true if the column has a default value or auto_increment,
// indicating it should be wrapped with Generated<T> in the output.
func isGenerated(col *schema.Column) bool {
	if col.Default != nil {
		return true
	}
	for _, attr := range col.Attrs {
		if _, ok := attr.(*sqlite.AutoIncrement); ok {
			return true
		}
	}
	return false
}

// schemaTypeToBase maps an Atlas schema.Type to a TypeScript base type string.
func schemaTypeToBase(t schema.Type) string {
	if t == nil {
		return "unknown"
	}
	switch v := t.(type) {
	case *schema.IntegerType:
		return "number"
	case *schema.FloatType:
		return "number"
	case *schema.DecimalType:
		return "number"
	case *schema.StringType:
		return "string"
	case *schema.BinaryType:
		return "Uint8Array"
	case *schema.BoolType:
		return "boolean"
	case *schema.TimeType:
		return "string"
	case *schema.JSONType:
		return "string"
	case *schema.EnumType:
		if len(v.Values) == 0 {
			return "string"
		}
		vals := make([]string, len(v.Values))
		for i, val := range v.Values {
			vals[i] = fmt.Sprintf("%q", val)
		}
		return strings.Join(vals, " | ")
	case *schema.UnsupportedType:
		// SQLite type affinity fallback: apply SQLite's own rules
		return sqliteAffinityFallback(v.T)
	default:
		return "unknown"
	}
}

// sqliteAffinityFallback applies SQLite type affinity rules for types
// that Atlas couldn't fully resolve (UnsupportedType).
// https://www.sqlite.org/datatype3.html
func sqliteAffinityFallback(raw string) string {
	upper := strings.ToUpper(strings.TrimSpace(raw))
	switch {
	case strings.Contains(upper, "INT"):
		return "number"
	case strings.Contains(upper, "CHAR"),
		strings.Contains(upper, "CLOB"),
		strings.Contains(upper, "TEXT"):
		return "string"
	case strings.Contains(upper, "BLOB"), upper == "":
		return "Uint8Array"
	case strings.Contains(upper, "REAL"),
		strings.Contains(upper, "FLOA"),
		strings.Contains(upper, "DOUB"):
		return "number"
	case strings.Contains(upper, "NUMERIC"),
		strings.Contains(upper, "DECIMAL"):
		return "number"
	case upper == "BOOLEAN" || upper == "BOOL":
		return "boolean"
	case upper == "DATE" || upper == "DATETIME" || upper == "TIMESTAMP":
		return "string"
	case upper == "JSON" || upper == "JSONB":
		return "string"
	default:
		return "string"
	}
}
