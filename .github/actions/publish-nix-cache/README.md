# Publish Nix cache

Build one Nix installable and upload its output closure with `nix copy`.
An existing build is reused when its store paths are available.
The action does not upload unrelated store paths or all build-time dependencies.
Install Nix and check out the target repository before calling this action.

## Usage

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
- uses: totto2727-org/monorepo/.github/actions/setup-nix@<commit-sha>
  with:
    prepare-dev-shell: 'false'
- uses: totto2727-org/monorepo/.github/actions/publish-nix-cache@<commit-sha>
  with:
    installable: .#my-tool
  env:
    NIX_CACHE_URL: ${{ vars.NIX_CACHE_UPLOAD_URL }}
    NIX_CACHE_SIGNING_KEY: ${{ secrets.NIX_CACHE_SIGNING_KEY }}
    AWS_ACCESS_KEY_ID: ${{ secrets.R2_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.R2_SECRET_ACCESS_KEY }}
    AWS_EC2_METADATA_DISABLED: 'true'
```

Pin each action to a reviewed commit SHA.
Only run publishing in trusted jobs that have access to the write credentials, not on untrusted pull-request code.
The required `installable` input accepts one target such as `.#my-tool`, a development shell such as `.#devShells.x86_64-linux.default`, or an existing `/nix/store/...` path.
Build platform-specific targets on a runner that can build that platform, or configure a remote builder separately.

## Environment variables

| Variable                | Purpose                                                                                        |
| ----------------------- | ---------------------------------------------------------------------------------------------- |
| `NIX_CACHE_URL`         | Required destination store URL for `nix copy --to`.                                            |
| `NIX_CACHE_SIGNING_KEY` | Optional secret signing key contents, not a file path. Signs the output closure before upload. |
| `AWS_ACCESS_KEY_ID`     | Access key for an S3-compatible destination.                                                   |
| `AWS_SECRET_ACCESS_KEY` | Secret key for an S3-compatible destination.                                                   |
| `AWS_SESSION_TOKEN`     | Session token when the destination uses temporary AWS credentials.                             |

For R2, set `NIX_CACHE_UPLOAD_URL` to a destination such as:

```text
s3://my-cache?endpoint=ACCOUNT_ID.r2.cloudflarestorage.com&region=auto
```

The bucket must already exist and the credentials must permit uploads.
Use a Nix installation with S3 support.
Uploads use R2's standard S3 API directly, while clients can download through the authenticated Worker cache URL.
Do not put credentials in the URL.
Other store types use Nix's own authentication configuration.
An HTTP read-cache URL is not necessarily a writable destination.

The signing key is written to a private temporary file created by `mktemp` and removed when the step exits.
Signing local store paths requires a trusted Nix user.
Omit the key only when the closure already has signatures trusted by consumers, or the destination has its own signing process.
Keep signature verification enabled on consumers and configure the corresponding public key there.
The action does not change download-cache settings or disable signature checks.

See the Nix references for [`nix copy`](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-copy), [`nix store sign`](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-store-sign), and the [S3 binary cache store](https://nix.dev/manual/nix/stable/store/types/s3-binary-cache-store).
