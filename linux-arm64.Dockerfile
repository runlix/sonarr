ARG BUILDER_REF="docker.io/library/debian:bookworm-slim@sha256:817e6cf99d6fc127ff4ffe8580049b60deba0adfbbb2bd65ddc3ef8fbb7aade0"
ARG BASE_REF="ghcr.io/runlix/distroless-runtime-v2-canary:stable@sha256:87dd2c28ec8bb85c31ad99a3138f570598ce0b6c3cb51b72cc23b4fa5d4031d4"
ARG PACKAGE_URL="https://github.com/Sonarr/Sonarr/releases/download/v4.0.17.2952/Sonarr.main.4.0.17.2952.linux-arm64.tar.gz"

FROM ${BUILDER_REF} AS fetch

# Redeclare ARG in this stage so it's available for use in RUN commands
ARG PACKAGE_URL

WORKDIR /app

# Use BuildKit cache mounts to persist apt cache between builds
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /app/bin \
 && curl -L -f "${PACKAGE_URL}" -o sonarr.tar.gz \
 && tar -xzf sonarr.tar.gz -C /app/bin --strip-components=1 \
 && chmod +x /app/bin/Sonarr \
 && rm sonarr.tar.gz

FROM ${BUILDER_REF} AS sonarr-deps

# Use BuildKit cache mounts to persist apt cache between builds
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    sqlite3 \
    ffmpeg \
    mediainfo \
 && rm -rf /var/lib/apt/lists/*

FROM ${BASE_REF}

ARG LIB_DIR=aarch64-linux-gnu

COPY --from=fetch /app /app
COPY --from=sonarr-deps /usr/bin/sqlite3 /usr/bin/sqlite3
COPY --from=sonarr-deps /usr/bin/ffmpeg /usr/bin/ffmpeg
COPY --from=sonarr-deps /usr/bin/mediainfo /usr/bin/mediainfo
COPY --from=sonarr-deps /usr/lib/${LIB_DIR}/libsqlite3.so.* /usr/lib/${LIB_DIR}/
COPY --from=sonarr-deps /usr/lib/${LIB_DIR}/libavcodec.so.* \
                        /usr/lib/${LIB_DIR}/libavformat.so.* \
                        /usr/lib/${LIB_DIR}/libavutil.so.* \
                        /usr/lib/${LIB_DIR}/libswscale.so.* \
                        /usr/lib/${LIB_DIR}/
COPY --from=sonarr-deps /usr/lib/${LIB_DIR}/libmediainfo.so.* \
                        /usr/lib/${LIB_DIR}/libzen.so.* \
                        /usr/lib/${LIB_DIR}/

WORKDIR /app/bin
USER 65532:65532
ENTRYPOINT ["/app/bin/Sonarr", "-nobrowser", "-data=/config"]
