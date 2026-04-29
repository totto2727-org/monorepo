package main

import (
	"testing"

	"ariga.io/atlas/sql/schema"
	"ariga.io/atlas/sql/sqlite"
)

func TestTsType_InnerType(t *testing.T) {
	tests := []struct {
		name string
		typ  tsType
		want string
	}{
		{"plain number", tsType{base: "number", nullable: false, generated: false}, "number"},
		{"plain string", tsType{base: "string", nullable: false, generated: false}, "string"},
		{"nullable string", tsType{base: "string", nullable: true, generated: false}, "string | null"},
		{"nullable number", tsType{base: "number", nullable: true, generated: false}, "number | null"},
		{"generated number", tsType{base: "number", nullable: false, generated: true}, "Generated<number>"},
		{"generated string", tsType{base: "string", nullable: false, generated: true}, "Generated<string>"},
		{"generated nullable string", tsType{base: "string", nullable: true, generated: true}, "Generated<string | null>"},
		{"generated nullable number", tsType{base: "number", nullable: true, generated: true}, "Generated<number | null>"},
		{"plain Uint8Array", tsType{base: "Uint8Array", nullable: false, generated: false}, "Uint8Array"},
		{"nullable Uint8Array", tsType{base: "Uint8Array", nullable: true, generated: false}, "Uint8Array | null"},
		{"plain boolean", tsType{base: "boolean", nullable: false, generated: false}, "boolean"},
		{"generated boolean", tsType{base: "boolean", nullable: false, generated: true}, "Generated<boolean>"},
		{"enum type", tsType{base: `"a" | "b"`, nullable: false, generated: false}, `"a" | "b"`},
		{"nullable enum type", tsType{base: `"a" | "b"`, nullable: true, generated: false}, `"a" | "b" | null`},
		{"generated enum type", tsType{base: `"a" | "b"`, nullable: false, generated: true}, `Generated<"a" | "b">`},
		{"generated nullable enum type", tsType{base: `"a" | "b"`, nullable: true, generated: true}, `Generated<"a" | "b" | null>`},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.typ.innerType()
			if got != tt.want {
				t.Errorf("innerType() = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestSchemaTypeToBase(t *testing.T) {
	tests := []struct {
		name string
		typ  schema.Type
		want string
	}{
		{"IntegerType", &schema.IntegerType{T: "integer"}, "number"},
		{"FloatType", &schema.FloatType{T: "real"}, "number"},
		{"DecimalType", &schema.DecimalType{T: "decimal"}, "number"},
		{"StringType", &schema.StringType{T: "text"}, "string"},
		{"BinaryType", &schema.BinaryType{T: "blob"}, "Uint8Array"},
		{"BoolType", &schema.BoolType{T: "boolean"}, "boolean"},
		{"TimeType", &schema.TimeType{T: "datetime"}, "string"},
		{"JSONType", &schema.JSONType{T: "json"}, "string"},
		{"EnumType with values", &schema.EnumType{Values: []string{"active", "inactive"}}, `"active" | "inactive"`},
		{"EnumType single value", &schema.EnumType{Values: []string{"only"}}, `"only"`},
		{"EnumType empty", &schema.EnumType{Values: []string{}}, "string"},
		{"EnumType three values", &schema.EnumType{Values: []string{"a", "b", "c"}}, `"a" | "b" | "c"`},
		{"UnsupportedType BIGINT", &schema.UnsupportedType{T: "BIGINT"}, "number"},
		{"UnsupportedType VARCHAR", &schema.UnsupportedType{T: "VARCHAR(255)"}, "string"},
		{"UnsupportedType BLOB", &schema.UnsupportedType{T: "BLOB"}, "Uint8Array"},
		{"UnsupportedType BOOLEAN", &schema.UnsupportedType{T: "BOOLEAN"}, "boolean"},
		{"nil type", nil, "unknown"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := schemaTypeToBase(tt.typ)
			if got != tt.want {
				t.Errorf("schemaTypeToBase() = %q, want %q", got, tt.want)
			}
		})
	}
}

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
		// Boolean
		{"BOOLEAN", "boolean"},
		{"BOOL", "boolean"},
		// Date/time
		{"DATE", "string"},
		{"DATETIME", "string"},
		{"TIMESTAMP", "string"},
		// JSON
		{"JSON", "string"},
		{"JSONB", "string"},
		// Default fallback
		{"UNKNOWN_TYPE", "string"},
		{"custom_thing", "string"},
		// Whitespace trimming
		{"  real  ", "number"},
		{"  TEXT  ", "string"},
		// Case insensitivity
		{"integer", "number"},
		{"Real", "number"},
		{"Boolean", "boolean"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := sqliteAffinityFallback(tt.input)
			if got != tt.want {
				t.Errorf("sqliteAffinityFallback(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestIsGenerated(t *testing.T) {
	tests := []struct {
		name string
		col  *schema.Column
		want bool
	}{
		{
			name: "no default no auto_increment",
			col: &schema.Column{
				Name: "name",
				Type: &schema.ColumnType{Type: &schema.StringType{T: "text"}},
			},
			want: false,
		},
		{
			name: "with default value",
			col: &schema.Column{
				Name:    "status",
				Type:    &schema.ColumnType{Type: &schema.StringType{T: "text"}},
				Default: &schema.Literal{V: "'draft'"},
			},
			want: true,
		},
		{
			name: "with auto_increment",
			col: &schema.Column{
				Name:  "id",
				Type:  &schema.ColumnType{Type: &schema.IntegerType{T: "integer"}},
				Attrs: []schema.Attr{&sqlite.AutoIncrement{}},
			},
			want: true,
		},
		{
			name: "with both default and auto_increment",
			col: &schema.Column{
				Name:    "id",
				Type:    &schema.ColumnType{Type: &schema.IntegerType{T: "integer"}},
				Default: &schema.Literal{V: "0"},
				Attrs:   []schema.Attr{&sqlite.AutoIncrement{}},
			},
			want: true,
		},
		{
			name: "with non-autoincrement attr",
			col: &schema.Column{
				Name: "name",
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
			got := isGenerated(tt.col)
			if got != tt.want {
				t.Errorf("isGenerated() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestColumnToTsType(t *testing.T) {
	tests := []struct {
		name string
		col  *schema.Column
		want tsType
	}{
		{
			name: "plain text column",
			col: &schema.Column{
				Name: "name",
				Type: &schema.ColumnType{Type: &schema.StringType{T: "text"}, Null: false},
			},
			want: tsType{base: "string", nullable: false, generated: false},
		},
		{
			name: "nullable text column",
			col: &schema.Column{
				Name: "bio",
				Type: &schema.ColumnType{Type: &schema.StringType{T: "text"}, Null: true},
			},
			want: tsType{base: "string", nullable: true, generated: false},
		},
		{
			name: "generated integer column (auto_increment)",
			col: &schema.Column{
				Name:  "id",
				Type:  &schema.ColumnType{Type: &schema.IntegerType{T: "integer"}, Null: false},
				Attrs: []schema.Attr{&sqlite.AutoIncrement{}},
			},
			want: tsType{base: "number", nullable: false, generated: true},
		},
		{
			name: "generated text column (default)",
			col: &schema.Column{
				Name:    "status",
				Type:    &schema.ColumnType{Type: &schema.StringType{T: "text"}, Null: false},
				Default: &schema.Literal{V: "'draft'"},
			},
			want: tsType{base: "string", nullable: false, generated: true},
		},
		{
			name: "nullable generated text column",
			col: &schema.Column{
				Name:    "description",
				Type:    &schema.ColumnType{Type: &schema.StringType{T: "text"}, Null: true},
				Default: &schema.Literal{V: "'unknown'"},
			},
			want: tsType{base: "string", nullable: true, generated: true},
		},
		{
			name: "plain integer column",
			col: &schema.Column{
				Name: "count",
				Type: &schema.ColumnType{Type: &schema.IntegerType{T: "integer"}, Null: false},
			},
			want: tsType{base: "number", nullable: false, generated: false},
		},
		{
			name: "nullable integer column",
			col: &schema.Column{
				Name: "age",
				Type: &schema.ColumnType{Type: &schema.IntegerType{T: "integer"}, Null: true},
			},
			want: tsType{base: "number", nullable: true, generated: false},
		},
		{
			name: "blob column",
			col: &schema.Column{
				Name: "data",
				Type: &schema.ColumnType{Type: &schema.BinaryType{T: "blob"}, Null: false},
			},
			want: tsType{base: "Uint8Array", nullable: false, generated: false},
		},
		{
			name: "boolean column",
			col: &schema.Column{
				Name: "active",
				Type: &schema.ColumnType{Type: &schema.BoolType{T: "boolean"}, Null: false},
			},
			want: tsType{base: "boolean", nullable: false, generated: false},
		},
		{
			name: "real column",
			col: &schema.Column{
				Name: "price",
				Type: &schema.ColumnType{Type: &schema.FloatType{T: "real"}, Null: false},
			},
			want: tsType{base: "number", nullable: false, generated: false},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := columnToTsType(tt.col)
			if got.base != tt.want.base || got.nullable != tt.want.nullable || got.generated != tt.want.generated {
				t.Errorf("columnToTsType() = {base:%q, nullable:%v, generated:%v}, want {base:%q, nullable:%v, generated:%v}",
					got.base, got.nullable, got.generated, tt.want.base, tt.want.nullable, tt.want.generated)
			}
		})
	}
}
