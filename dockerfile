# STAGE 1 — fetch Sonarr binaries
FROM debian:bookworm-slim AS fetch

ARG SONARR_VERSION=4.0.16.2944

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
 && rm -rf /var/lib/apt/lists/* \
 && curl -L "https://services.sonarr.tv/v1/download/main/${SONARR_VERSION}?version=linux" \
      -o sonarr.zip \
 && unzip sonarr.zip -d /app \
 && rm sonarr.zip

# STAGE 2 — distroless final image
FROM ghcr.io/runlix/distroless-runtime:release

COPY --from=fetch /app /app

WORKDIR /app

USER 65532:65532

ENTRYPOINT ["./Sonarr"]
