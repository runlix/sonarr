# STAGE 1 — fetch Sonarr binaries
FROM debian:bookworm-slim AS fetch

ARG VERSION
ARG AMD64_URL
ARG SBRANCH=main

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
 && rm -rf /var/lib/apt/lists/* \
 && echo "DEBUG: VERSION=${VERSION}" \
 && echo "DEBUG: SBRANCH=${SBRANCH}" \
 && if [ -n "${AMD64_URL}" ]; then \
      DOWNLOAD_URL="${AMD64_URL}"; \
      echo "DEBUG: Using AMD64_URL from VERSION.json: ${DOWNLOAD_URL}"; \
    else \
      DOWNLOAD_URL="https://github.com/Sonarr/Sonarr/releases/download/v${VERSION}/Sonarr.${SBRANCH}.${VERSION}.linux-musl-x64.tar.gz"; \
      echo "DEBUG: Constructed URL: ${DOWNLOAD_URL}"; \
    fi \
 && curl -L -f "${DOWNLOAD_URL}" -o sonarr.tar.gz \
 && echo "DEBUG: File size after download:" \
 && ls -lh sonarr.tar.gz \
 && tar -xzf sonarr.tar.gz -C /app --strip-components=1 \
 && rm sonarr.tar.gz

# STAGE 2 — distroless final image
FROM ghcr.io/runlix/distroless-runtime:release

COPY --from=fetch /app /app

WORKDIR /app

USER 65532:65532

ENTRYPOINT ["./Sonarr"]
