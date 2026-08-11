ARG SANDBOX_IMAGE=ghcr.io/totto2727-org/monorepo/sandbox-base@sha256:df12730051f9c1c920c250be35e04a56332dd9d31f2a2dc839042f74c90fe1c0

FROM ${SANDBOX_IMAGE} AS builder

ARG TARGETARCH
USER sandbox
WORKDIR /sandbox

RUN case "$TARGETARCH" in \
      amd64) moon_arch=x86_64 ;; \
      arm64) moon_arch=aarch64 ;; \
      *) printf 'Unsupported architecture: %s\n' "$TARGETARCH" >&2; exit 1 ;; \
    esac && \
    cd /tmp && \
    moon_archive="moonbit-linux-$moon_arch.tar.gz" && \
    curl -fsSLO "https://cli.moonbitlang.com/binaries/latest/$moon_archive" && \
    curl -fsSLO "https://cli.moonbitlang.com/binaries/latest/$moon_archive.sha256" && \
    sha256sum -c "$moon_archive.sha256" && \
    tar -xzf "$moon_archive" -C /sandbox/.moon && \
    chmod +x /sandbox/.moon/bin/* /sandbox/.moon/bin/internal/tcc && \
    moon -C /sandbox/.moon/lib/core bundle --warn-list -a --all && \
    rm "$moon_archive" "$moon_archive.sha256"

COPY --chown=sandbox:sandbox . /tmp/monorepo

RUN cd /tmp/monorepo && \
    moon update && \
    moon install /tmp/monorepo/mbt/app/c-plugin-v2/src \
      --bin /sandbox/.local/bin \
      --target-dir /sandbox/.cache/c-plugin-v2-build && \
    test -x /sandbox/.local/bin/c-plugin-v2 && \
    rm -rf /tmp/monorepo /sandbox/.cache/c-plugin-v2-build

FROM ${SANDBOX_IMAGE}

LABEL org.opencontainers.image.source="https://github.com/totto2727-org/monorepo"

USER sandbox
WORKDIR /sandbox

COPY --from=builder --chown=sandbox:sandbox /sandbox/.local/bin/c-plugin-v2 /sandbox/.local/bin/c-plugin-v2
COPY --chown=sandbox:sandbox mbt/app/c-plugin-v2/src/e2e/init.sh /sandbox/e2e/init.sh
COPY --chown=sandbox:sandbox mbt/app/c-plugin-v2/src/e2e/sync.sh /sandbox/e2e/sync.sh
COPY --chown=sandbox:sandbox mbt/app/c-plugin-v2/src/e2e/sync_recursive.sh /sandbox/e2e/sync_recursive.sh

RUN chmod +x /sandbox/.local/bin/c-plugin-v2 /sandbox/e2e/init.sh /sandbox/e2e/sync.sh /sandbox/e2e/sync_recursive.sh && \
    ln -s /sandbox/.local/bin/c-plugin-v2 /sandbox/.local/bin/c-plugin

ENTRYPOINT ["/sandbox/e2e/init.sh"]
