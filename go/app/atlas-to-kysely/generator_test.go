package main

import (
	"os"
	"testing"
)

func TestGenerateKysely_FixtureMatch(t *testing.T) {
	src, err := os.ReadFile("fixture/schema.hcl")
	if err != nil {
		t.Fatalf("failed to read fixture/schema.hcl: %v", err)
	}

	realm, err := ParseHCLBytes(src)
	if err != nil {
		t.Fatalf("failed to parse HCL: %v", err)
	}

	got, err := GenerateKysely(realm)
	if err != nil {
		t.Fatalf("GenerateKysely failed: %v", err)
	}

	expected, err := os.ReadFile("fixture/generated.ts")
	if err != nil {
		t.Fatalf("failed to read fixture/generated.ts: %v", err)
	}

	if got != string(expected) {
		t.Errorf("output does not match fixture/generated.ts\n--- got ---\n%s\n--- want ---\n%s", got, string(expected))
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
