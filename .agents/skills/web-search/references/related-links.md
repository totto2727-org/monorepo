# Related-Link Selection with Jev

Use this reference when a fetched page's saved `links` inventory is needed to find related pages.
Prefer the installed official `typesafe-ai` skill from `typesafe-ai/skills`; if unavailable, read the [official documentation index](https://docs.typesafe.ai/llms.txt), [Choice](https://docs.typesafe.ai/primitives/choice), and [Score](https://docs.typesafe.ai/primitives/score) guidance as needed.
Use [OpenConnector](../../open-connector/SKILL.md) for all Jev API access and `oo connector schema typesafe_ai.evaluate` for the current schema.
Execute TypeSafe/Jev directly through OOMOL/OpenConnector, never through Monid, even if a Monid catalog endpoint offers the same model.
Do not distribute a local copy of the official skill or route around a missing gateway connection.

## Keep Candidate Inventories out of the Main Context

Use the completed TinyFish response saved by the [web-search workflow](../SKILL.md#workflow).
Derive unique URL candidates from its `links` arrays locally, assign task-local IDs, and write the inventory to a file without printing it.

For multiple source pages, retain a separate URL-to-source-page map on disk when provenance matters.
IDs are task-local and stable only for this saved inventory; never join answers against a newly regenerated inventory.
Validate candidate schemes, credentials, hosts, and destinations under the task's access policy before sending them for selection or retrieval.
Exclude non-web schemes and unauthorized private or local-network destinations; an apparently safe URL does not authorize unsafe redirects.
Code may deduplicate and apply explicit source-domain or version constraints, but do not silently remove potentially relevant URLs just to fit a model limit.
When image files themselves are requested, derive candidates from `image_links` instead; bare filenames cannot establish visual relevance.

## Ask for the Right Judgment

Give Jev the user's research goal and explicit interpretation when the request is ambiguous, plus the candidate IDs and URL strings.
Only include anchor text, titles, or snippets if the provider actually supplied them; never invent missing context from the URL.
Construct the evaluation JSON from saved files with `jq --slurpfile` or a local serializer, run `oo connector run typesafe_ai --action evaluate --data @input.json --json > response.json`, then read answers from the saved file with `jq`.
Do not send the inventory to the main model merely to assemble the request.

Choose the primitive according to the question, not the desired number of HTTP calls:

- **Several useful pages:** prefer an independent Score for each candidate, using the same explicit relevance rubric for every URL.
  For example, order levels as unrelated, tangential, useful background, and directly useful for the stated task.
  Batch independent questions over shared state, partitioning requests when required by model limits or cost.
  Alternatively, use one Noul per candidate for the probability that it satisfies a clearly defined relevance condition.
- **One best next page:** use Choice with candidate IDs and a `none` option.
  Its probabilities compare competing options, not each page's independent relevance.
  More than one useful page can split probability, and a zero or rounded-low probability does not prove irrelevance.
- **A shortlist from an existing Choice result:** taking the top few candidates is allowed, but label the values as Choice probabilities.
  Do not describe that shortlist as a calibrated relevance threshold or force a single winner when the task needs several sources.

For Choice, respect the current maximum of 255 options, including `none`.
For larger inventories, partition candidates, retain several plausible candidates per partition, and re-evaluate the combined shortlist if a global Choice ranking is needed.
Do not compare or sum probabilities from separate Choice questions as though they shared one distribution.
A shared Score rubric or per-candidate Noul avoids that particular normalization problem, but thresholds still require validation on the intended task.

## Consume Only a Small, Verified Selection

1. Read `.data.answers` from the saved `oo` JSON response; follow the official CLI guidance if the command fails.
2. Rank with local code and retain a task-appropriate bounded set, typically up to three URLs for an initial investigation.
   Use relevance and uncertainty criteria appropriate to the task; a top-k limit is a budget cap, not proof that every selected page is useful.
   Allow zero matches and keep a way to broaden the search or fetch candidate titles when the evidence is too weak.
3. Resolve each chosen ID by exact lookup in the saved inventory; never execute a model-generated URL or shell command.
   Recheck access constraints and source scope before fetching, and track visited URLs to avoid recursive loops.
4. Read only the selected URLs and their clearly labeled scores or probabilities into the main context with `jq`.
   Keep full distributions and unused candidates in the saved files.
5. Fetch the selected URLs with TinyFish in a bounded batch, keeping `format: "markdown"` and `links: true`.
   Save the response, inspect each URL's outcome, then use `jq` to read relevant Markdown sections and verify that they answer the question.
   Apply a page/call budget and stop when there is enough evidence.

URL-based selection estimates where relevant information might be, not whether the destination actually supports a claim.
Opaque IDs, missing page text, and ambiguous names require additional evidence or another retrieval route.
Do not claim restoration of TinyFish's lost label-to-URL associations.
Report model usage and material costs when relevant: moving the inventory to Jev reduces the main model's context load, not necessarily total tokens or spending.

See the official [semantic find](https://docs.typesafe.ai/cookbooks/semantic_find) and [reranking](https://docs.typesafe.ai/cookbooks/rerank_typesafe) examples for evaluation design, without assuming their sample thresholds fit this workflow.
