package main

import (
	"flag"
	"fmt"
	"os"
)

func main() {
	input := flag.String("input", "", "Path to schema.hcl (required)")
	output := flag.String("output", "", "Output .ts file path (default: stdout)")
	caseMode := flag.String("case", "camel", "Column name case: camel, snake, none")
	flag.StringVar(input, "i", "", "Path to schema.hcl (shorthand)")
	flag.StringVar(output, "o", "", "Output .ts file path (shorthand)")
	flag.Parse()

	if *input == "" {
		fmt.Fprintln(os.Stderr, "Error: --input is required")
		flag.Usage()
		os.Exit(1)
	}

	switch *caseMode {
	case "camel", "snake", "none":
	default:
		fmt.Fprintf(os.Stderr, "Error: --case must be camel, snake, or none (got %q)\n", *caseMode)
		os.Exit(1)
	}

	src, err := os.ReadFile(*input)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: cannot read %s: %v\n", *input, err)
		os.Exit(1)
	}

	realm, err := ParseHCLBytes(src)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: failed to parse HCL: %v\n", err)
		os.Exit(1)
	}

	opts := GenerateOptions{CaseMode: *caseMode}
	out, err := GenerateKysely(realm, opts)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: codegen failed: %v\n", err)
		os.Exit(1)
	}

	if *output != "" {
		if err := os.WriteFile(*output, []byte(out), 0644); err != nil {
			fmt.Fprintf(os.Stderr, "Error: cannot write %s: %v\n", *output, err)
			os.Exit(1)
		}
		tableCount := len(realm.Schemas[0].Tables)
		fmt.Fprintf(os.Stderr, "✓ Generated: %s  (%d table(s))\n", *output, tableCount)
	} else {
		fmt.Print(out)
	}
}
