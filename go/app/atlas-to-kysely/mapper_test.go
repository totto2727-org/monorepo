package main

import (
	"testing"

	"ariga.io/atlas/sql/schema"
	"ariga.io/atlas/sql/sqlite"
)

// TestTsTypeInnerType (SC-U1): tsType formatter — base × nullable × generated.
func TestTsTypeInnerType(t *testing.T) {
	const enumUnion = `"a" | "b"`

	tests := []struct {
		name string
		typ  tsType
		want string
	}{
		{"plain number", tsType{base: "number"}, "number"},
		{"plain string", tsType{base: "string"}, "string"},
		{"plain boolean", tsType{base: "boolean"}, "boolean"},
		{"plain Uint8Array", tsType{base: "Uint8Array"}, "Uint8Array"},

		{"nullable number", tsType{base: "number", nullable: true}, "number | null"},
		{"nullable string", tsType{base: "string", nullable: true}, "string | null"},
		{"nullable boolean", tsType{base: "boolean", nullable: true}, "boolean | null"},
		{"nullable Uint8Array", tsType{base: "Uint8Array", nullable: true}, "Uint8Array | null"},

		{"generated number", tsType{base: "number", generated: true}, "Generated<number>"},
		{"generated string", tsType{base: "string", generated: true}, "Generated<string>"},
		{"generated boolean", tsType{base: "boolean", generated: true}, "Generated<boolean>"},
		{"generated Uint8Array", tsType{base: "Uint8Array", generated: true}, "Generated<Uint8Array>"},

		{"nullable + generated number", tsType{base: "number", nullable: true, generated: true}, "Generated<number | null>"},
		{"nullable + generated string", tsType{base: "string", nullable: true, generated: true}, "Generated<string | null>"},
		{"nullable + generated boolean", tsType{base: "boolean", nullable: true, generated: true}, "Generated<boolean | null>"},
		{"nullable + generated Uint8Array", tsType{base: "Uint8Array", nullable: true, generated: true}, "Generated<Uint8Array | null>"},

		{"plain enum union", tsType{base: enumUnion}, enumUnion},
		{"nullable enum union", tsType{base: enumUnion, nullable: true}, enumUnion + ` | null`},
		{"generated enum union", tsType{base: enumUnion, generated: true}, `Generated<` + enumUnion + `>`},
		{"nullable + generated enum union", tsType{base: enumUnion, nullable: true, generated: true}, `Generated<` + enumUnion + ` | null>`},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.typ.innerType(); got != tt.want {
				t.Errorf("innerType() = %q, want %q", got, tt.want)
			}
		})
	}
}

// TestSchemaTypeToBase (SC-U2): Atlas schema.Type → TS base type dispatcher.
func TestSchemaTypeToBase(t *testing.T) {
	tests := []struct {
		name string
		typ  schema.Type
		want string
	}{
		// Primitive types
		{"IntegerType", &schema.IntegerType{T: "integer"}, "number"},
		{"FloatType", &schema.FloatType{T: "real"}, "number"},
		{"DecimalType", &schema.DecimalType{T: "decimal"}, "number"},
		{"StringType", &schema.StringType{T: "text"}, "string"},
		{"BoolType", &schema.BoolType{T: "boolean"}, "boolean"},
		// Binary
		{"BinaryType", &schema.BinaryType{T: "blob"}, "Uint8Array"},
		// Date / JSON → string
		{"TimeType datetime", &schema.TimeType{T: "datetime"}, "string"},
		{"JSONType", &schema.JSONType{T: "json"}, "string"},
		// Enum unions
		{"EnumType empty values", &schema.EnumType{Values: []string{}}, "string"},
		{"EnumType single value", &schema.EnumType{Values: []string{"only"}}, `"only"`},
		{"EnumType multi value", &schema.EnumType{Values: []string{"a", "b", "c"}}, `"a" | "b" | "c"`},
		// UnsupportedType falls through to sqliteAffinityFallback
		{"UnsupportedType BIGINT", &schema.UnsupportedType{T: "BIGINT"}, "number"},
		{"UnsupportedType VARCHAR", &schema.UnsupportedType{T: "VARCHAR(255)"}, "string"},
		{"UnsupportedType BLOB", &schema.UnsupportedType{T: "BLOB"}, "Uint8Array"},
		{"UnsupportedType BOOLEAN", &schema.UnsupportedType{T: "BOOLEAN"}, "boolean"},
		// Defensive: nil
		{"nil type", nil, "unknown"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := schemaTypeToBase(tt.typ); got != tt.want {
				t.Errorf("schemaTypeToBase() = %q, want %q", got, tt.want)
			}
		})
	}
}

// TestSqliteAffinityFallback (SC-U3): SQLite type-name affinity rules.
func TestSqliteAffinityFallback(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		// INT affinity
		{"BIGINT", "number"},
		{"TINYINT", "number"},
		{"SMALLINT", "number"},
		{"MEDIUMINT", "number"},
		{"INT", "number"},
		{"INTEGER", "number"},
		// TEXT affinity
		{"VARCHAR(255)", "string"},
		{"CHAR(10)", "string"},
		{"CLOB", "string"},
		{"TEXT", "string"},
		{"NVARCHAR(100)", "string"},
		// BLOB affinity
		{"BLOB", "Uint8Array"},
		{"", "Uint8Array"},
		// REAL affinity
		{"REAL", "number"},
		{"FLOAT", "number"},
		{"DOUBLE", "number"},
		{"DOUBLE PRECISION", "number"},
		// NUMERIC affinity
		{"NUMERIC", "number"},
		{"DECIMAL", "number"},
		{"DECIMAL(10,2)", "number"},
		// Boolean special case
		{"BOOLEAN", "boolean"},
		{"BOOL", "boolean"},
		// Date / time / JSON → string
		{"DATE", "string"},
		{"DATETIME", "string"},
		{"TIMESTAMP", "string"},
		{"JSON", "string"},
		{"JSONB", "string"},
		// Unknown / default fallback → string
		{"UNKNOWN_TYPE", "string"},
		{"custom_thing", "string"},
		// Whitespace tolerance
		{"  real  ", "number"},
		{"  TEXT  ", "string"},
		// Case insensitivity
		{"integer", "number"},
		{"Real", "number"},
		{"Boolean", "boolean"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			if got := sqliteAffinityFallback(tt.input); got != tt.want {
				t.Errorf("sqliteAffinityFallback(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

// TestIsGenerated (SC-U4): default / auto_increment detection.
func TestIsGenerated(t *testing.T) {
	tests := []struct {
		name string
		col  *schema.Column
		want bool
	}{
		{
			name: "no default no auto_increment",
			col: &schema.Column{
				Type: &schema.ColumnType{Type: &schema.StringType{T: "text"}},
			},
			want: false,
		},
		{
			name: "with default value",
			col: &schema.Column{
				Type:    &schema.ColumnType{Type: &schema.StringType{T: "text"}},
				Default: &schema.Literal{V: "'draft'"},
			},
			want: true,
		},
		{
			name: "with auto_increment",
			col: &schema.Column{
				Type:  &schema.ColumnType{Type: &schema.IntegerType{T: "integer"}},
				Attrs: []schema.Attr{&sqlite.AutoIncrement{}},
			},
			want: true,
		},
		{
			name: "default + auto_increment",
			col: &schema.Column{
				Type:    &schema.ColumnType{Type: &schema.IntegerType{T: "integer"}},
				Default: &schema.Literal{V: "0"},
				Attrs:   []schema.Attr{&sqlite.AutoIncrement{}},
			},
			want: true,
		},
		{
			name: "unrelated attr only",
			col: &schema.Column{
				Type: &schema.ColumnType{Type: &schema.StringType{T: "text"}},
				Attrs: []schema.Attr{
					&schema.Comment{Text: "just a comment"},
				},
			},
			want: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := isGenerated(tt.col); got != tt.want {
				t.Errorf("isGenerated() = %v, want %v", got, tt.want)
			}
		})
	}
}

// TestColumnToTsType (SC-U5): composition of schemaTypeToBase × Null × isGenerated.
func TestColumnToTsType(t *testing.T) {
	tests := []struct {
		name string
		col  *schema.Column
		want tsType
	}{
		{
			name: "plain text",
			col: &schema.Column{
				Type: &schema.ColumnType{Type: &schema.StringType{T: "text"}},
			},
			want: tsType{base: "string"},
		},
		{
			name: "nullable text",
			col: &schema.Column{
				Type: &schema.ColumnType{Type: &schema.StringType{T: "text"}, Null: true},
			},
			want: tsType{base: "string", nullable: true},
		},
		{
			name: "auto_increment integer",
			col: &schema.Column{
				Type:  &schema.ColumnType{Type: &schema.IntegerType{T: "integer"}},
				Attrs: []schema.Attr{&sqlite.AutoIncrement{}},
			},
			want: tsType{base: "number", generated: true},
		},
		{
			name: "default text",
			col: &schema.Column{
				Type:    &schema.ColumnType{Type: &schema.StringType{T: "text"}},
				Default: &schema.Literal{V: "'draft'"},
			},
			want: tsType{base: "string", generated: true},
		},
		{
			name: "nullable + default text",
			col: &schema.Column{
				Type:    &schema.ColumnType{Type: &schema.StringType{T: "text"}, Null: true},
				Default: &schema.Literal{V: "'unknown'"},
			},
			want: tsType{base: "string", nullable: true, generated: true},
		},
		{
			name: "blob",
			col: &schema.Column{
				Type: &schema.ColumnType{Type: &schema.BinaryType{T: "blob"}},
			},
			want: tsType{base: "Uint8Array"},
		},
		{
			name: "boolean",
			col: &schema.Column{
				Type: &schema.ColumnType{Type: &schema.BoolType{T: "boolean"}},
			},
			want: tsType{base: "boolean"},
		},
		{
			name: "real",
			col: &schema.Column{
				Type: &schema.ColumnType{Type: &schema.FloatType{T: "real"}},
			},
			want: tsType{base: "number"},
		},
		// TC-U-M33: gap-fill — enum column composition
		{
			name: "enum union",
			col: &schema.Column{
				Type: &schema.ColumnType{
					Type: &schema.EnumType{Values: []string{"open", "closed"}},
				},
			},
			want: tsType{base: `"open" | "closed"`},
		},
		{
			name: "nullable enum union",
			col: &schema.Column{
				Type: &schema.ColumnType{
					Type: &schema.EnumType{Values: []string{"yes", "no"}},
					Null: true,
				},
			},
			want: tsType{base: `"yes" | "no"`, nullable: true},
		},
		// TC-U-M34: gap-fill — defensive nil type path
		{
			name: "nil type defensive",
			col: &schema.Column{
				Type: &schema.ColumnType{Type: nil},
			},
			want: tsType{base: "unknown"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := columnToTsType(tt.col)
			if got != tt.want {
				t.Errorf("columnToTsType() = %+v, want %+v", got, tt.want)
			}
		})
	}
}
