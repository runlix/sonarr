ARG BUILDER_REF="docker.io/library/debian:bookworm-slim@sha256:63a496b5d3b99214b39f5ed70eb71a61e590a77979c79cbee4faf991f8c0783e"
ARG BASE_REF="ghcr.io/runlix/distroless-runtime-v2-canary:stable@sha256:dbb2f5ac1cf480fca2dd08750c87771b6c2ef097fc248196fe72fbd13c82a3c2"
ARG PACKAGE_URL="https://github.com/Sonarr/Sonarr/releases/download/v4.0.17.2952/Sonarr.main.4.0.17.2952.linux-x64.tar.gz"

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

ARG LIB_DIR=x86_64-linux-gnu

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
