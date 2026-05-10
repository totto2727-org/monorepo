package main

import (
	"testing"
)

// TestTransformName (SC-U10): camelCase flag dispatcher.
func TestTransformName(t *testing.T) {
	tests := []struct {
		name      string
		input     string
		camelCase bool
		want      string
	}{
		// camelCase=true delegates to toKyselyCamelCase
		{"camel snake input", "user_id", true, "userId"},
		{"camel already camel", "userId", true, "userId"},
		{"camel UPPER_SNAKE preserved (upperCase=false)", "USER_ID", true, "USERID"},
		{"camel empty input", "", true, ""},
		// camelCase=false is identity
		{"identity snake input", "user_id", false, "user_id"},
		{"identity camel input", "userId", false, "userId"},
		{"identity UPPER_SNAKE", "USER_ID", false, "USER_ID"},
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

// TestTableInterfaceName (SC-U11): replaceNonWordChars → toKyselyPascalCase composition.
func TestTableInterfaceName(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		// Plain identifiers
		{"user", "User"},
		{"user_account", "UserAccount"},
		{"userAccount", "UserAccount"},
		// Non-word characters get replaced with `_`, then PascalCased
		{"user-account", "UserAccount"},
		{"user.profile", "UserProfile"},
		// `$` is preserved through the pascal case
		{"my$table", "My$table"},
		// Digit-leading
		{"2nd_table", "2ndTable"},
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

// TestToKyselyCamelCase (SC-U6): port of kysely-codegen's case-converter.
//
// kysely-codegen calls `createCamelCaseMapper({})` (default opts,
// upperCase=false), so screaming snake stays screaming.
func TestToKyselyCamelCase(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		// Standard snake_case
		{"access_token", "accessToken"},
		{"user_id", "userId"},
		{"created_at", "createdAt"},
		{"refresh_token_expires_at", "refreshTokenExpiresAt"},
		// UPPER_SNAKE_CASE — upperCase=false leaves screaming intact
		{"USER_ID", "USERID"},
		{"HTTP_STATUS", "HTTPSTATUS"},
		{"MAX_RETRY_COUNT", "MAXRETRYCOUNT"},
		{"ID", "ID"},
		// Already camelCase / passthrough
		{"userId", "userId"},
		{"accessToken", "accessToken"},
		{"already", "already"},
		{"myFieldName", "myFieldName"},
		// Single char
		{"a", "a"},
		{"A", "A"},
		{"id", "id"},
		// Empty input
		{"", ""},
		// Digits
		{"ITEM_2_NAME", "ITEM2NAME"},
		{"2nd_item", "2ndItem"},
		{"123", "123"},
		// Underscore edges
		{"_private", "_Private"},
		{"trailing_", "trailing"},
		{"double__under", "doubleUnder"},
		{"___", "_"},
		{"_", "_"},
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

// TestToKyselyPascalCase (SC-U6): toUpperFirst(toKyselyCamelCase(s)).
func TestToKyselyPascalCase(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		// snake / kebab / camel / UPPER_SNAKE inputs
		{"user_account", "UserAccount"},
		{"user-account", "User-account"}, // `-` is non-word; not pre-replaced here
		{"userAccount", "UserAccount"},
		{"USER_ID", "USERID"},
		// Edges
		{"", ""},
		{"a", "A"},
		{"A", "A"},
		{"_private", "_Private"},
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

// TestReplaceNonWordChars (SC-U7): mirrors JS `s.replaceAll(/[^\w$]/g, '_')`.
//
// `\w` is `[A-Za-z0-9_]`; `$` is also retained.
func TestReplaceNonWordChars(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		// Non-word characters become `_`
		{"a-b", "a_b"},
		{"a.b", "a_b"},
		{"a b", "a_b"},
		// `$` is retained
		{"a$b", "a$b"},
		{"$only", "$only"},
		// `_` is retained (already a word char)
		{"a_b", "a_b"},
		// Digits / letters retained
		{"abc123", "abc123"},
		// All non-word
		{"---", "___"},
		// Empty
		{"", ""},
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

// TestSerializeKey (SC-U8): IDENTIFIER_REGEXP-based bare / quoted dispatch.
//
// The regex `^[$A-Z_a-z][\w$]*$` matches valid TS identifiers; non-matches
// are double-quoted via strconv.Quote.
func TestSerializeKey(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		// Bare (matches regex)
		{"user_id", "user_id"},
		{"userId", "userId"},
		{"_private", "_private"},
		{"$id", "$id"},
		{"USER_ID", "USER_ID"},
		// TS reserved words are valid object property names → bare
		{"class", "class"},
		{"default", "default"},
		// Quoted (regex fails)
		{"2nd", `"2nd"`},             // digit-leading
		{"user.name", `"user.name"`}, // contains `.`
		{"with space", `"with space"`},
		// Empty input fails the regex (requires ≥1 starting char) → quoted
		{"", `""`},
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

// TestLocaleKeyLess (SC-U9): localeCompare-style sort comparator.
//
// Primary level case-insensitive; secondary level lowercase before
// uppercase on case-only ties (en-US ICU default).
func TestLocaleKeyLess(t *testing.T) {
	tests := []struct {
		name string
		a, b string
		want bool
	}{
		// Primary level: alphabetical, case-insensitive
		{"a < b", "a", "b", true},
		{"A < B", "A", "B", true},
		{"a < B (case-insensitive)", "a", "B", true},
		{"B > a", "B", "a", false},
		// Equal keys → not less
		{"abc == abc", "abc", "abc", false},
		// Case-only tie: lower before upper
		{"a < A on case-only tie", "a", "A", true},
		{"A > a on case-only tie", "A", "a", false},
		// Multi-char prefix ordering
		{"item < user", "item", "user", true},
		// Digits in identifiers — string comparison (NOT numeric):
		// JS `localeCompare` defaults to ICU's [<digit>...] string ordering,
		// so "item10" < "item2" because '1' < '2' in code-point order.
		{"item10 < item2 (string compare)", "item10", "item2", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := localeKeyLess(tt.a, tt.b)
			if got != tt.want {
				t.Errorf("localeKeyLess(%q, %q) = %v, want %v", tt.a, tt.b, got, tt.want)
			}
		})
	}
}
