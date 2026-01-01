# Sonarr

Kubernetes-native distroless Docker image for [Sonarr](https://github.com/sonarr/sonarr) - a TV show collection manager.

## Purpose

Provides a minimal, secure Docker image for running Sonarr in Kubernetes environments. Built on the `distroless-runtime` base image with only the essential dependencies required for Sonarr to function.

## Features

- Distroless base (no shell, minimal attack surface)
- Kubernetes-native permissions (no s6-overlay)
- Read-only root filesystem
- Non-root execution
- Minimal image size (~100MB vs ~500MB)

## Usage

### Docker

```bash
docker run -d \
  --name sonarr \
  -p 8989:8989 \
  -v /path/to/config:/config \
  ghcr.io/runlix/sonarr:release-latest
```

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sonarr
spec:
  template:
    spec:
      containers:
      - name: sonarr
        image: ghcr.io/runlix/sonarr:release-latest
        ports:
        - containerPort: 8989
        volumeMounts:
        - name: config
          mountPath: /config
        securityContext:
          runAsUser: 1012
          runAsGroup: 1011
          supplementalGroups: [1010, 1003]
          readOnlyRootFilesystem: true
          capabilities:
            drop: ["ALL"]
      volumes:
      - name: config
        persistentVolumeClaim:
          claimName: sonarr-config
      securityContext:
        fsGroup: 1011
```

## Tags

See [tags.json](tags.json) for available tags.

## Environment Variables

- `SONARR__SERVER__PORT`: Server port (default: 8989)

## License

GPL-3.0
