# @infra/cloudflare

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
