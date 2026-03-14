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
