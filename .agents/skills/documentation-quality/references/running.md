# Running document evaluations

Use Node.js 22 or later and `curl`.
In this repository, prefix commands with `nix develop --command` to use the pinned environment.
The evaluator does not install dependencies or obtain secrets for you.

## Configure the gateway

Supply `OPENCONNECTOR_BASE_URL` as a trusted complete HTTPS origin and `OPENCONNECTOR_TOKEN` through the existing secret environment.
Do not put either a provider API key or a token value in a manifest.
The script calls only `/v1/actions/typesafe_ai.evaluate` on that origin.
There is no direct-provider fallback.

Use the installed `open-connector` skill to discover `typesafe_ai.evaluate` and call `typesafe_ai.list_models` before the first live run.
If unavailable, use the [gateway skill in this repository](../../../../external-information/skills/open-connector/SKILL.md).
Prefer the installed official `typesafe-ai` skill for question design and model limits, with the [official documentation index](https://docs.typesafe.ai/llms.txt) as fallback.
The Action wraps TypeSafe's request as `{"input":{"state":...,"model":...,"questions":...}}` and returns typed answers under `data.answers`.
Question and answer collections are keyed objects, not arrays.
See the official [API reference](https://docs.typesafe.ai/api.md), [Choice primitive](https://docs.typesafe.ai/primitives/choice.md), and [model limits](https://docs.typesafe.ai/models.md).
Gateway limits and account rate limits may be lower than model limits.

The requested model can be an available alias such as `jev-latest`.
The report records the returned concrete model for every response so alias changes are visible.
Compare runs using the same resolved model when measuring a rule change.

## Prepare a manifest

Select English source documentation by default and exclude translated editions from `documents`.
Review the English source before translation; assess translation fidelity and target-language correctness separately rather than applying this rubric again after translation.
The evaluator does not automatically detect source language or translation status, so enforce this scope when preparing the manifest.

Paths are relative to the manifest file unless absolute.
Use exactly one of `rulesFile` or inline `rules`.
The [bundled rules](rules.json) are a starting point, not a requirement to apply every rule to every document.

```json
{
  "model": "jev-latest",
  "threshold": 0.8,
  "rulesFile": "../../plugins/totto2727-coding/skills/documentation-quality/references/rules.json",
  "documents": [
    {
      "id": "guide",
      "path": "../../docs/guide.md",
      "purpose": "Create a project and run its default page.",
      "audience": "Developers using the public package.",
      "ruleIds": ["consumer-contract", "focused-unit", "reader-route"]
    }
  ]
}
```

This example assumes a manifest in `<repository>/tmp/review/`; adjust paths for the installed skill and your repository.
Add more entries to `documents` to evaluate many documents through the same worker pool.
Optional `context` is a string containing relevant external evidence, such as excerpts from linked setup guides.
Do not put expected verdicts, preferred revisions, or editorial instructions in evidence.

By default, the evaluator uses Markdown heading sections and preserves fenced code.
For selected paragraph groups, supply inclusive one-based source ranges:

```json
{
  "sections": [
    {
      "id": "setup-note",
      "startLine": 14,
      "endLine": 18,
      "headingPath": ["Setup", "Runtime requirements"]
    }
  ]
}
```

Add this field to a document entry, not to the manifest root.
The runner extracts the actual source range rather than accepting an unrelated replacement string.
Inspect the selected range to keep paragraphs, tables, lists, warnings, and their explanations complete.
Fenced code must not be cut in half.
Explicit selections evaluate only those sections, while page rules still examine the complete page.

Each request contains the reader purpose, audience, selected unit, heading context, and complete page.
Large evidence is rejected rather than silently truncated.
The byte guard is not a tokenizer or a guarantee that a provider's token limit will be met.
For a long page, choose coherent smaller source documents with the context they need, or use a reasoning reviewer instead.

## Inspect before sending

Create the output directory, then run:

```bash
node plugins/totto2727-coding/skills/documentation-quality/scripts/evaluate.mjs \
  --manifest tmp/review/manifest.json \
  --output tmp/review/plan.json \
  --concurrency 4 \
  --dry-run
```

Dry runs do not require gateway credentials and do not make network calls.
Inspect the planned ranges, evidence, requests, and questions before authorizing a live run.
Confirm that both the gateway and its configured model provider may receive the document contents.
Do not publish the plan if its source text is private.

Remove `--dry-run` and choose a new report path to evaluate through OOMOL.
Concurrency defaults to 4 and is bounded; raising it is not permission to exceed the account's rate limit.
Transient gateway responses may be retried within a fixed limit; authentication or malformed-response failures are not accepted as judgments.

## Read the report

The report retains document and rule identities, scope, source ranges, typed answers, probabilities, resolved model, and errors.
Source IDs and file paths are report metadata, not hints about the expected verdict.
A Choice's confidence and its selected option's probability are different fields; do not assume they are equal.

| Process exit | Meaning                                                                                            |
| ------------ | -------------------------------------------------------------------------------------------------- |
| `0`          | Dry run completed, or every submitted live check passed above the threshold                        |
| `1`          | At least one live result failed, abstained, had low confidence, or encountered an evaluation error |
| `2`          | The manifest, environment, source ranges, output path, or invocation could not be prepared         |

A successful dry run is not an acceptance result.
`not_applicable` and `insufficient_context` stay visible for review rather than silently reducing the coverage denominator.

For a failing or uncertain answer, match `answers[].questionId` to `questions[].id` within the same evaluation and use its `rule.id` in the [rule index](rules.md).
Read only that rule's guide, then compare the actual source range and page context with its example and exceptions.
Do not send the guide's labeled samples back as evidence in a blind evaluation or infer a rationale that Jev did not return.
Keep `not_applicable`, `insufficient_context`, low confidence, and missing results separate from positive passes; do not average away a critical failure.

For an evaluation with `status: "error"`, inspect its `error` field and the gateway or response validation failure rather than editing document prose.
Resolve access or request-format problems through the configured gateway, without bypassing authentication or silently accepting missing answers.
If preparation exits `2`, correct the manifest, environment, source range, or output path before retrying.
Keep earlier reports and use a new output path so a failed run remains inspectable.

## Validate the local implementation

```bash
nix develop --command vp test run plugins/totto2727-coding/skills/documentation-quality/scripts
nix develop --command vp check
git diff --check
```

The local tests validate segmentation, request/response boundaries, aggregation, and failure behavior with controlled transport.
They do not prove Jev's semantic accuracy or gateway availability.
A live evaluation against independently labeled examples supplies separate evidence of accuracy for those examples and the returned model.
