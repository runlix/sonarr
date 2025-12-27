# Global build args (available to all stages)
ARG BASE_IMAGE=ghcr.io/runlix/distroless-runtime:release

# STAGE 1 — fetch Sonarr binaries
FROM debian:bookworm-slim AS fetch

ARG VERSION
ARG TARGETARCH=amd64
ARG AMD64_URL
ARG ARM64_URL
ARG SBRANCH=main

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
 && if [ "$TARGETARCH" = "arm64" ]; then \
        curl -L -f "${ARM64_URL}" -o sonarr.tar.gz; \
    else \
        curl -L -f "${AMD64_URL}" -o sonarr.tar.gz; \
    fi \
 && tar -xzf sonarr.tar.gz -C /app/bin --strip-components=1 \
 && chmod +x /app/bin/Sonarr \
 && rm sonarr.tar.gz

# STAGE 2 — install Sonarr-specific runtime packages
FROM debian:bookworm-slim AS sonarr-deps

# Use BuildKit cache mounts to persist apt cache between builds
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    sqlite3 \
    ffmpeg \
    mediainfo \
 && rm -rf /var/lib/apt/lists/*

# STAGE 3 — distroless final image
FROM ${BASE_IMAGE}

# Set architecture-specific library directory
ARG TARGETARCH=amd64
ARG LIB_DIR=x86_64-linux-gnu
# LIB_DIR will be set by build script for arm64 builds

COPY --from=fetch /app /app
# Copy binaries from sonarr-deps stage (kept separate for clarity)
COPY --from=sonarr-deps /usr/bin/sqlite3 /usr/bin/sqlite3
COPY --from=sonarr-deps /usr/bin/ffmpeg /usr/bin/ffmpeg
COPY --from=sonarr-deps /usr/bin/mediainfo /usr/bin/mediainfo
# Copy shared libraries - combined into fewer layers by grouping related libraries
# SQLite libraries
COPY --from=sonarr-deps /usr/lib/${LIB_DIR}/libsqlite3.so.* /usr/lib/${LIB_DIR}/
# FFmpeg libraries (avcodec, avformat, avutil, swscale)
COPY --from=sonarr-deps /usr/lib/${LIB_DIR}/libavcodec.so.* \
                        /usr/lib/${LIB_DIR}/libavformat.so.* \
                        /usr/lib/${LIB_DIR}/libavutil.so.* \
                        /usr/lib/${LIB_DIR}/libswscale.so.* \
                        /usr/lib/${LIB_DIR}/
# MediaInfo libraries (mediainfo, zen)
COPY --from=sonarr-deps /usr/lib/${LIB_DIR}/libmediainfo.so.* \
                        /usr/lib/${LIB_DIR}/libzen.so.* \
                        /usr/lib/${LIB_DIR}/

WORKDIR /app/bin

USER 65532:65532

ENTRYPOINT ["/app/bin/Sonarr", "-nobrowser", "-data=/config"]
