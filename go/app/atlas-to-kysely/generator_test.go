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
			tsPath:  "fixture/generated.ts",
			opts:    GenerateOptions{CaseMode: "camel"},
		},
		{
			name:    "generated_wrapper",
			hclPath: "fixture/generated_wrapper/schema.hcl",
			tsPath:  "fixture/generated_wrapper/generated.ts",
			opts:    GenerateOptions{CaseMode: "camel"},
		},
		{
			name:    "snake_case",
			hclPath: "fixture/snake/schema.hcl",
			tsPath:  "fixture/snake/generated.ts",
			opts:    GenerateOptions{CaseMode: "snake"},
		},
		{
			name:    "camel_kysely_upper_snake",
			hclPath: "fixture/camel_kysely/schema.hcl",
			tsPath:  "fixture/camel_kysely/generated.ts",
			opts:    GenerateOptions{CaseMode: "camel"},
		},
		{
			name:    "all_types",
			hclPath: "fixture/all_types/schema.hcl",
			tsPath:  "fixture/all_types/generated.ts",
			opts:    GenerateOptions{CaseMode: "none"},
		},
		{
			name:    "generated_nullable",
			hclPath: "fixture/generated_nullable/schema.hcl",
			tsPath:  "fixture/generated_nullable/generated.ts",
			opts:    GenerateOptions{CaseMode: "none"},
		},
		{
			name:    "empty_table",
			hclPath: "fixture/empty_table/schema.hcl",
			tsPath:  "fixture/empty_table/generated.ts",
			opts:    GenerateOptions{CaseMode: "none"},
		},
		{
			name:    "single_table",
			hclPath: "fixture/single_table/schema.hcl",
			tsPath:  "fixture/single_table/generated.ts",
			opts:    GenerateOptions{CaseMode: "none"},
		},
		{
			name:    "none_case_mode",
			hclPath: "fixture/none/schema.hcl",
			tsPath:  "fixture/none/generated.ts",
			opts:    GenerateOptions{CaseMode: "none"},
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

func TestKyselyCamelCase(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		// Standard snake_case
		{"access_token", "accessToken"},
		{"user_id", "userId"},
		{"created_at", "createdAt"},
		{"refresh_token_expires_at", "refreshTokenExpiresAt"},
		// UPPER_SNAKE_CASE (Kysely upperCase=true behavior)
		{"USER_ID", "userId"},
		{"HTTP_STATUS", "httpStatus"},
		{"MAX_RETRY_COUNT", "maxRetryCount"},
		{"UPDATED_AT", "updatedAt"},
		{"ID", "id"},
		// Already camelCase (should pass through)
		{"userId", "userId"},
		{"accessToken", "accessToken"},
		{"already", "already"},
		// Single character
		{"a", "a"},
		{"A", "a"},
		// Empty string
		{"", ""},
		// No underscores
		{"id", "id"},
		// Mixed case with digits
		{"ITEM_2_NAME", "item2Name"},
		// Leading underscore: first char '_' is kept, next char uppercased
		{"_private", "_Private"},
		// Trailing underscore: underscore is stripped
		{"trailing_", "trailing"},
		// Consecutive underscores: treated as single separator
		{"double__under", "doubleUnder"},
		// All underscores: first underscore kept, rest stripped
		{"___", "_"},
		// Digits only
		{"123", "123"},
		// Digit-starting name
		{"2nd_item", "2ndItem"},
		// Mixed camelCase passthrough
		{"myFieldName", "myFieldName"},
		// Single char + underscore
		{"a_b", "aB"},
		// Single underscore: first char is underscore, kept as-is
		{"_", "_"},
		// Uppercase single + underscore
		{"A_B", "aB"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := kyselyCamelCase(tt.input)
			if got != tt.want {
				t.Errorf("kyselyCamelCase(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestToCamelCase(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"access_token", "accessToken"},
		{"user_id", "userId"},
		{"email_verified", "emailVerified"},
		{"id", "id"},
		{"created_at", "createdAt"},
		{"refresh_token_expires_at", "refreshTokenExpiresAt"},
		{"", ""},
		{"already", "already"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := toCamelCase(tt.input)
			if got != tt.want {
				t.Errorf("toCamelCase(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestToPascalCase(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"user", "User"},
		{"account", "Account"},
		{"user_profiles", "UserProfiles"},
		{"", ""},
		{"user-profiles", "UserProfiles"},
		{"a", "A"},
		{"item_2", "Item2"},
		{"USER_ID", "USERID"},
		{"single", "Single"},
		{"multi_word_name", "MultiWordName"},
		{"kebab-case-name", "KebabCaseName"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := toPascalCase(tt.input)
			if got != tt.want {
				t.Errorf("toPascalCase(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestConvertColumnName(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		caseMode string
		want     string
	}{
		{"camel mode", "user_id", "camel", "userId"},
		{"snake mode", "user_id", "snake", "user_id"},
		{"none mode", "user_id", "none", "user_id"},
		{"default (empty) falls back to camel", "user_id", "", "userId"},
		{"camel with UPPER_SNAKE", "USER_ID", "camel", "userId"},
		{"snake preserves UPPER_SNAKE", "USER_ID", "snake", "USER_ID"},
		{"none preserves UPPER_SNAKE", "USER_ID", "none", "USER_ID"},
		{"camel with already camelCase", "userId", "camel", "userId"},
		{"snake with already camelCase", "userId", "snake", "userId"},
		{"camel with single word", "id", "camel", "id"},
		{"snake with single word", "id", "snake", "id"},
		{"camel with multi-part", "access_token_expires_at", "camel", "accessTokenExpiresAt"},
		{"snake with multi-part", "access_token_expires_at", "snake", "access_token_expires_at"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := convertColumnName(tt.input, tt.caseMode)
			if got != tt.want {
				t.Errorf("convertColumnName(%q, %q) = %q, want %q", tt.input, tt.caseMode, got, tt.want)
			}
		})
	}
}

func TestIsAllUpperCaseSnakeCase(t *testing.T) {
	tests := []struct {
		input string
		want  bool
	}{
		{"USER_ID", true},
		{"HTTP_STATUS", true},
		{"ID", true},
		{"A_1_B", true},
		{"MAX_RETRY_COUNT", true},
		{"123", true},
		{"_", true},
		{"__", true},
		{"", true},
		{"userId", false},
		{"User_Id", false},
		{"user_id", false},
		{"HTTPStatus", false},
		{"a", false},
		{"ABc", false},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := isAllUpperCaseSnakeCase(tt.input)
			if got != tt.want {
				t.Errorf("isAllUpperCaseSnakeCase(%q) = %v, want %v", tt.input, got, tt.want)
			}
		})
	}
}
