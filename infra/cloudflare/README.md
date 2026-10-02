# @infra/cloudflare

## AI Gateway

This stack manages an authenticated Cloudflare AI Gateway using the native Pulumi `AiGateway` resource.
The production gateway ID is `iac-prod-ai-gateway`.
Other stacks use `iac-<stack>-ai-gateway`.
Deletion protection is enabled, request log collection is disabled, and the default response cache TTL and rate limit values are set to zero.
These defaults avoid retaining coding prompts in gateway logs or caching responses by default.
Clients can override logging and caching behavior with per-request headers.
This does not change the upstream model provider's data retention policy.
No provider API keys or gateway runtime tokens are created, stored, or exported by this stack.

Run the maintained local checks and Pulumi-mocked regression tests from the repository root:

```bash
vp check infra/cloudflare
vp test run --dir infra/cloudflare
```

The regression tests check resource inputs and connection outputs without accessing Cloudflare.
They do not replace a real Pulumi preview or an end-to-end request.

The Cloudflare infrastructure token in ESC needs `AI Gateway Read` and `AI Gateway Edit` permissions for the configured account.
Keep it separate from a client runtime token with `AI Gateway Run` permission.
Run tokens are account-scoped, not restricted to this gateway.

Preview from the repository root before explicitly applying the stack:

```bash
pulumi preview --cwd infra/cloudflare --stack production --non-interactive --diff
```

Applying requires a separate, explicit deployment decision:

```bash
pulumi up --cwd infra/cloudflare --stack production
```

After deployment, retrieve the non-secret connection outputs:

```bash
pulumi stack output aiGatewayId --cwd infra/cloudflare --stack production
pulumi stack output aiGatewayBaseUrl --cwd infra/cloudflare --stack production
```

### OpenCode Go

The installed Pulumi Cloudflare SDK does not expose a Custom Provider registration resource, so that account-level configuration is not managed by this stack.
In Cloudflare's **AI Gateway > Custom Providers** dashboard, register or reuse an enabled provider with slug `opencode-go` and base URL `https://opencode.ai`.
Do not put `/zen/go/v1` in both the provider base URL and the client URL.
The gateway alone is not sufficient to use OpenCode Go until this provider is registered and the client credentials are configured.

Set the client's provider-native base URL to `<aiGatewayBaseUrl>/custom-opencode-go/zen/go/v1`.
Keep each model's native API format: `/chat/completions` for OpenAI-compatible models, `/responses` for Responses API models, and `/messages` for Anthropic-compatible models.
The `/compat` endpoint is not a replacement for all three formats.
Use the OpenCode Go API key for upstream provider authentication and send `cf-aig-authorization: Bearer <AI_GATEWAY_RUN_TOKEN>` for gateway authentication.
Preserve the coding agent's own User-Agent and its stable conversation session header, such as `x-opencode-session`, through the gateway.

For a post-deployment smoke test, supply the runtime credentials through your secret manager and keep the same `OPENCODE_SESSION_ID` across requests in one conversation:

```bash
: "${OPENCODE_API_KEY:?Configure the OpenCode Go API key}"
: "${AI_GATEWAY_RUN_TOKEN:?Configure an AI Gateway Run token}"
: "${OPENCODE_SESSION_ID:?Set a stable conversation session ID}"
GATEWAY_BASE_URL="$(pulumi stack output aiGatewayBaseUrl --cwd infra/cloudflare --stack production)"
curl --fail-with-body --silent --show-error --max-time 120 \
  "${GATEWAY_BASE_URL}/custom-opencode-go/zen/go/v1/chat/completions" \
  --header "Authorization: Bearer ${OPENCODE_API_KEY}" \
  --header "cf-aig-authorization: Bearer ${AI_GATEWAY_RUN_TOKEN}" \
  --header "x-opencode-session: ${OPENCODE_SESSION_ID}" \
  --header 'User-Agent: monorepo-coding-agent/1.0' \
  --header 'cf-aig-skip-cache: true' \
  --header 'Content-Type: application/json' \
  --data '{"model":"deepseek-v4-flash","messages":[{"role":"user","content":"Suggest a TypeScript function that adds two numbers."}],"max_tokens":128}'
```

This test consumes OpenCode Go usage and must only be run after explicitly deploying and configuring the provider.
Confirm that the authenticated request succeeds, then validate streaming and tool calls with the actual coding agent before relying on the integration.

References: [Pulumi AiGateway](https://www.pulumi.com/registry/packages/cloudflare/api-docs/aigateway/), [Authenticated Gateway](https://developers.cloudflare.com/ai-gateway/configuration/authentication/), [Custom Providers](https://developers.cloudflare.com/ai-gateway/configuration/custom-providers/), and [OpenCode Go](https://opencode.ai/docs/go/).

## Pulumi ESC

### cloudflare/production

```yaml
values:
  cloudflare:
    CLOUDFLARE_API_TOKEN:
      fn::secret:
        ciphertext: ZXNjeAAAAAEAAAIAsK2LxUtjJKuZoHb9wX3KYtl5u0kbpEh8UeQVSVZDmCqLITZiJASUyOU/GtWPBU4jdnGn9qHAGcxOP85eI0lsbKIRvwJ/HpO5ycmMwyRwz/s4rws3hcQSQg==
    CLOUDFLARE_ACCOUNT_ID: 5643a837ef66765e7881c0831a36ebed
  environmentVariables:
    CLOUDFLARE_ACCOUNT_ID: ${cloudflare.CLOUDFLARE_ACCOUNT_ID}
  pulumiConfig:
    cloudflare:apiToken: ${cloudflare.CLOUDFLARE_API_TOKEN}
```
