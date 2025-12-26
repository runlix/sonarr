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
 && curl -L -f "${AMD64_URL}" -o sonarr.tar.gz \
 && tar -xzf sonarr.tar.gz -C /app --strip-components=1 \
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

WORKDIR /app

USER 65532:65532

ENTRYPOINT ["./Sonarr"]
