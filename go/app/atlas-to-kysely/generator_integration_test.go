package main

import (
	"os"
	"testing"
)

// TestGenerateKysely_Integration covers the integration-level success criteria
// (SC-1 to SC-7 in qa-design.integration.md) using a single representative
// schema (fixture/main/schema.hcl) executed under both CamelCase modes. Edge
// cases and helper-level invariants are deferred to unit tests.
func TestGenerateKysely_Integration(t *testing.T) {
	const hclPath = "fixture/main/schema.hcl"

	src, err := os.ReadFile(hclPath)
	if err != nil {
		t.Fatalf("failed to read %s: %v", hclPath, err)
	}
	realm, err := ParseHCLBytes(src)
	if err != nil {
		t.Fatalf("failed to parse HCL: %v", err)
	}

	tests := []struct {
		id     string
		name   string
		opts   GenerateOptions
		golden string
	}{
		{
			id:     "TC-001",
			name:   "camel_case_true",
			opts:   GenerateOptions{CamelCase: true},
			golden: "fixture/main/generated.camel.ts.fixture",
		},
		{
			id:     "TC-002",
			name:   "camel_case_false",
			opts:   GenerateOptions{CamelCase: false},
			golden: "fixture/main/generated.snake.ts.fixture",
		},
	}

	for _, tt := range tests {
		t.Run(tt.id+"_"+tt.name, func(t *testing.T) {
			got, err := GenerateKysely(realm, tt.opts)
			if err != nil {
				t.Fatalf("GenerateKysely failed: %v", err)
			}

			expected, err := os.ReadFile(tt.golden)
			if err != nil {
				t.Fatalf("failed to read %s: %v", tt.golden, err)
			}

			if got != string(expected) {
				t.Errorf("output does not match %s\n--- got ---\n%s\n--- want ---\n%s", tt.golden, got, string(expected))
			}
		})
	}
}
