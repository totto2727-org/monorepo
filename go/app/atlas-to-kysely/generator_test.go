package main

import (
	"os"
	"testing"
)

func TestGenerateKysely_Fixtures(t *testing.T) {
	tests := []struct {
		name    string
		hclPath string
		tsPath  string
		opts    GenerateOptions
	}{
		{
			name:    "default_camel",
			hclPath: "fixture/schema.hcl",
			tsPath:  "fixture/generated.ts.fixture",
			opts:    GenerateOptions{CamelCase: true},
		},
		{
			name:    "generated_wrapper",
			hclPath: "fixture/generated_wrapper/schema.hcl",
			tsPath:  "fixture/generated_wrapper/generated.ts.fixture",
			opts:    GenerateOptions{CamelCase: true},
		},
		{
			name:    "snake_identity",
			hclPath: "fixture/snake/schema.hcl",
			tsPath:  "fixture/snake/generated.ts.fixture",
			opts:    GenerateOptions{CamelCase: false},
		},
		{
			name:    "camel_kysely_upper_snake",
			hclPath: "fixture/camel_kysely/schema.hcl",
			tsPath:  "fixture/camel_kysely/generated.ts.fixture",
			opts:    GenerateOptions{CamelCase: true},
		},
		{
			name:    "all_types",
			hclPath: "fixture/all_types/schema.hcl",
			tsPath:  "fixture/all_types/generated.ts.fixture",
			opts:    GenerateOptions{CamelCase: false},
		},
		{
			name:    "generated_nullable",
			hclPath: "fixture/generated_nullable/schema.hcl",
			tsPath:  "fixture/generated_nullable/generated.ts.fixture",
			opts:    GenerateOptions{CamelCase: false},
		},
		{
			name:    "empty_table",
			hclPath: "fixture/empty_table/schema.hcl",
			tsPath:  "fixture/empty_table/generated.ts.fixture",
			opts:    GenerateOptions{CamelCase: false},
		},
		{
			name:    "single_table",
			hclPath: "fixture/single_table/schema.hcl",
			tsPath:  "fixture/single_table/generated.ts.fixture",
			opts:    GenerateOptions{CamelCase: false},
		},
		{
			name:    "none_identity",
			hclPath: "fixture/none/schema.hcl",
			tsPath:  "fixture/none/generated.ts.fixture",
			opts:    GenerateOptions{CamelCase: false},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			src, err := os.ReadFile(tt.hclPath)
			if err != nil {
				t.Fatalf("failed to read %s: %v", tt.hclPath, err)
			}

			realm, err := ParseHCLBytes(src)
			if err != nil {
				t.Fatalf("failed to parse HCL: %v", err)
			}

			got, err := GenerateKysely(realm, tt.opts)
			if err != nil {
				t.Fatalf("GenerateKysely failed: %v", err)
			}

			expected, err := os.ReadFile(tt.tsPath)
			if err != nil {
				t.Fatalf("failed to read %s: %v", tt.tsPath, err)
			}

			if got != string(expected) {
				t.Errorf("output does not match %s\n--- got ---\n%s\n--- want ---\n%s", tt.tsPath, got, string(expected))
			}
		})
	}
}

func TestToKyselyCamelCase(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		// Standard snake_case → camelCase
		{"access_token", "accessToken"},
		{"user_id", "userId"},
		{"created_at", "createdAt"},
		{"refresh_token_expires_at", "refreshTokenExpiresAt"},
		// UPPER_SNAKE_CASE: with kysely-codegen's default upperCase=false
		// the helper does NOT pre-lowercase, so consecutive uppercase
		// segments fuse into one screaming token.
		{"USER_ID", "USERID"},
		{"HTTP_STATUS", "HTTPSTATUS"},
		{"MAX_RETRY_COUNT", "MAXRETRYCOUNT"},
		{"UPDATED_AT", "UPDATEDAT"},
		{"ID", "ID"},
		// Already camelCase or single-token: passthrough.
		{"userId", "userId"},
		{"accessToken", "accessToken"},
		{"already", "already"},
		{"a", "a"},
		{"A", "A"},
		{"", ""},
		{"id", "id"},
		// Digit handling around underscores.
		{"ITEM_2_NAME", "ITEM2NAME"},
		{"2nd_item", "2ndItem"},
		{"123", "123"},
		// Underscore edge cases.
		{"_private", "_Private"},
		{"trailing_", "trailing"},
		{"double__under", "doubleUnder"},
		{"___", "_"},
		{"_", "_"},
		// Mixed case passthrough (no underscores).
		{"myFieldName", "myFieldName"},
		// Single-letter pair.
		{"a_b", "aB"},
		{"A_B", "AB"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := toKyselyCamelCase(tt.input)
			if got != tt.want {
				t.Errorf("toKyselyCamelCase(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestToKyselyPascalCase(t *testing.T) {
	// toKyselyPascalCase = toUpperFirst(toKyselyCamelCase(s)).
	// Note: separator characters other than '_' (e.g. '-') are NOT
	// pre-replaced here; that step belongs to tableInterfaceName.
	tests := []struct {
		input string
		want  string
	}{
		{"user", "User"},
		{"account", "Account"},
		{"user_profiles", "UserProfiles"},
		{"", ""},
		{"a", "A"},
		{"item_2", "Item2"},
		{"USER_ID", "USERID"},
		{"single", "Single"},
		{"multi_word_name", "MultiWordName"},
		// Hyphens are preserved by toKyselyPascalCase alone.
		{"user-profiles", "User-profiles"},
		{"kebab-case-name", "Kebab-case-name"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := toKyselyPascalCase(tt.input)
			if got != tt.want {
				t.Errorf("toKyselyPascalCase(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestTableInterfaceName(t *testing.T) {
	// tableInterfaceName = toKyselyPascalCase(replaceNonWordChars(s)),
	// which mirrors SymbolCollection.set's preprocessing.
	tests := []struct {
		input string
		want  string
	}{
		{"user", "User"},
		{"user_profiles", "UserProfiles"},
		{"app_config", "AppConfig"},
		{"kebab-case-name", "KebabCaseName"},
		{"weird.dot", "WeirdDot"},
		{"with space", "WithSpace"},
		{"USER_ID", "USERID"},
		{"", ""},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := tableInterfaceName(tt.input)
			if got != tt.want {
				t.Errorf("tableInterfaceName(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestReplaceNonWordChars(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"kebab-case-name", "kebab_case_name"},
		{"app config", "app_config"},
		{"weird.dot", "weird_dot"},
		{"clean_word", "clean_word"},
		{"with$dollar", "with$dollar"},
		{"123abc", "123abc"},
		{"", ""},
		{"!@#$", "___$"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := replaceNonWordChars(tt.input)
			if got != tt.want {
				t.Errorf("replaceNonWordChars(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestTransformName(t *testing.T) {
	tests := []struct {
		name      string
		input     string
		camelCase bool
		want      string
	}{
		{"camel mode on snake input", "user_id", true, "userId"},
		{"identity on snake input", "user_id", false, "user_id"},
		{"camel on UPPER_SNAKE keeps screaming", "USER_ID", true, "USERID"},
		{"identity on UPPER_SNAKE", "USER_ID", false, "USER_ID"},
		{"camel idempotent on already camel", "userId", true, "userId"},
		{"identity on already camel", "userId", false, "userId"},
		{"camel on single word", "id", true, "id"},
		{"identity on single word", "id", false, "id"},
		{"camel multi-segment", "access_token_expires_at", true, "accessTokenExpiresAt"},
		{"identity multi-segment", "access_token_expires_at", false, "access_token_expires_at"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := transformName(tt.input, tt.camelCase)
			if got != tt.want {
				t.Errorf("transformName(%q, %v) = %q, want %q", tt.input, tt.camelCase, got, tt.want)
			}
		})
	}
}

func TestSerializeKey(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"userId", "userId"},
		{"user_id", "user_id"},
		{"_private", "_private"},
		{"$dollar", "$dollar"},
		{"A", "A"},
		{"_", "_"},
		// Keys that must be quoted.
		{"123abc", `"123abc"`},
		{"kebab-case", `"kebab-case"`},
		{"with space", `"with space"`},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := serializeKey(tt.input)
			if got != tt.want {
				t.Errorf("serializeKey(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestLocaleKeyLess(t *testing.T) {
	tests := []struct {
		a, b string
		want bool
	}{
		// Different primary level.
		{"apple", "banana", true},
		{"banana", "apple", false},
		{"apiKey", "userId", true},
		{"USERID", "apiKey", false}, // u > a primary
		// Equal strings.
		{"apple", "apple", false},
		// Case-only ties: lowercase comes first (en-US ICU default).
		{"apple", "Apple", true},
		{"Apple", "apple", false},
		{"id", "ID", true},
		{"ID", "id", false},
	}

	for _, tt := range tests {
		t.Run(tt.a+"_vs_"+tt.b, func(t *testing.T) {
			got := localeKeyLess(tt.a, tt.b)
			if got != tt.want {
				t.Errorf("localeKeyLess(%q, %q) = %v, want %v", tt.a, tt.b, got, tt.want)
			}
		})
	}
}
