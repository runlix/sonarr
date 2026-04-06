# Sonarr

`sonarr` publishes the Runlix container image for [Sonarr](https://github.com/Sonarr/Sonarr).

The current published image name is:

```text
ghcr.io/runlix/sonarr
```

Use a versioned stable manifest tag from [release.json](release.json):

```dockerfile
FROM ghcr.io/runlix/sonarr:<version>-stable
```

The authoritative published tags, digests, and source revision live in [release.json](release.json).

## What's Included

- Sonarr upstream binaries
- `sqlite3`
- `ffmpeg`
- `mediainfo`
- shared runtime libraries from `distroless-runtime-v2-canary`

The image keeps the distroless runtime model while layering in the Sonarr-specific binaries and media tooling it needs.

## Branch Layout

`main` owns metadata and automation config:

- `README.md`
- `links.json`
- `release.json`
- `renovate.json`
- `.github/workflows/validate-release-metadata.yml`

`release` owns build and publish inputs:

- `.ci/build.json`
- `.ci/smoke-test.sh`
- `linux-*.Dockerfile`
- `.github/workflows/validate-build.yml`
- `.github/workflows/publish-release.yml`

## Release Flow

Changes merge to `release`, where `Publish Release` builds the versioned `stable` and `debug` multi-arch manifests, attests them, optionally sends Telegram, and opens the sync PR back to `main`.

`main` validates metadata and config-only changes with `Validate Release Metadata`.

## Environment Variables

- `SONARR__SERVER__PORT`: server port, default `8989`

## License

GPL-3.0
