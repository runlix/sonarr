# STAGE 1 — fetch Sonarr binaries
FROM debian:bookworm-slim AS fetch

ARG VERSION
ARG AMD64_URL
ARG SBRANCH=main

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
 && rm -rf /var/lib/apt/lists/* \
 && echo "DEBUG: VERSION=${VERSION}" \
 && echo "DEBUG: SBRANCH=${SBRANCH}" \
 && if [ -n "${AMD64_URL}" ]; then \
      DOWNLOAD_URL="${AMD64_URL}"; \
      echo "DEBUG: Using AMD64_URL from VERSION.json: ${DOWNLOAD_URL}"; \
    else \
      DOWNLOAD_URL="https://services.sonarr.tv/v1/download/${SBRANCH}/${VERSION}?version=linux"; \
      echo "DEBUG: Constructed URL: ${DOWNLOAD_URL}"; \
    fi \
 && curl -L -f "${DOWNLOAD_URL}" -o sonarr.zip \
 && echo "DEBUG: File size after download:" \
 && ls -lh sonarr.zip \
 && file sonarr.zip \
 && unzip sonarr.zip -d /app \
 && rm sonarr.zip

# STAGE 2 — distroless final image
FROM ghcr.io/runlix/distroless-runtime:release

COPY --from=fetch /app /app

WORKDIR /app

USER 65532:65532

ENTRYPOINT ["./Sonarr"]
