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
 && mkdir -p /app/bin \
 && curl -L -f "${AMD64_URL}" -o sonarr.tar.gz \
 && echo "DEBUG: Archive contents:" && tar -tzf sonarr.tar.gz | head -20 \
 && tar -xzf sonarr.tar.gz -C /app/bin --strip-components=1 \
 && echo "DEBUG: Contents of /app/bin after extraction:" && ls -la /app/bin | head -20 \
 && echo "DEBUG: Looking for Sonarr binary:" && find /app -name "Sonarr" -type f 2>&1 || echo "DEBUG: Sonarr not found" \
 && chmod +x /app/bin/Sonarr 2>&1 || echo "DEBUG: Failed to chmod Sonarr" \
 && rm sonarr.tar.gz

# STAGE 2 — install Sonarr-specific runtime packages
FROM debian:bookworm-slim AS sonarr-deps

RUN apt-get update && apt-get install -y --no-install-recommends \
    sqlite3 \
    ffmpeg \
    mediainfo \
 && rm -rf /var/lib/apt/lists/*

# STAGE 3 — distroless final image
FROM ghcr.io/runlix/distroless-runtime:release

# Debug: Verify files after COPY (using a temporary stage since distroless has no shell)
FROM debian:bookworm-slim AS debug-check
COPY --from=fetch /app /app
RUN echo "DEBUG: Contents of /app after COPY:" && ls -la /app && \
    echo "DEBUG: Contents of /app/bin after COPY:" && ls -la /app/bin 2>&1 | head -20 && \
    echo "DEBUG: Sonarr binary check:" && test -f /app/bin/Sonarr && echo "Sonarr exists at /app/bin/Sonarr" || echo "Sonarr NOT found at /app/bin/Sonarr" && \
    find /app -name "Sonarr" -type f 2>&1 || echo "Sonarr not found anywhere"

# STAGE 3 — distroless final image
FROM ghcr.io/runlix/distroless-runtime:release

COPY --from=fetch /app /app
COPY --from=sonarr-deps /usr/bin/sqlite3 /usr/bin/sqlite3
COPY --from=sonarr-deps /usr/bin/ffmpeg /usr/bin/ffmpeg
COPY --from=sonarr-deps /usr/bin/mediainfo /usr/bin/mediainfo
COPY --from=sonarr-deps /usr/lib/x86_64-linux-gnu/libsqlite3.so.* /usr/lib/x86_64-linux-gnu/
COPY --from=sonarr-deps /usr/lib/x86_64-linux-gnu/libavcodec.so.* /usr/lib/x86_64-linux-gnu/
COPY --from=sonarr-deps /usr/lib/x86_64-linux-gnu/libavformat.so.* /usr/lib/x86_64-linux-gnu/
COPY --from=sonarr-deps /usr/lib/x86_64-linux-gnu/libavutil.so.* /usr/lib/x86_64-linux-gnu/
COPY --from=sonarr-deps /usr/lib/x86_64-linux-gnu/libswscale.so.* /usr/lib/x86_64-linux-gnu/
COPY --from=sonarr-deps /usr/lib/x86_64-linux-gnu/libmediainfo.so.* /usr/lib/x86_64-linux-gnu/
COPY --from=sonarr-deps /usr/lib/x86_64-linux-gnu/libzen.so.* /usr/lib/x86_64-linux-gnu/

WORKDIR /app/bin

USER 65532:65532

ENTRYPOINT ["/app/bin/Sonarr"]
 