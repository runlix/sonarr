#!/bin/bash
set -euo pipefail

# Local build script for sonarr with arm64-debug architecture
# This script builds the image locally for arm64 using the local
# distroless-runtime:arm64-debug-local base image, while GitHub Actions
# continues to build for amd64 by default.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default tag
TAG="${1:-sonarr:arm64-debug-local}"

echo "Building sonarr for arm64-debug architecture..."
echo "Tag: $TAG"
echo ""

# Check if VERSION.json exists
if [ ! -f "VERSION.json" ]; then
    echo "Error: VERSION.json not found in $SCRIPT_DIR"
    exit 1
fi

# Check if jq is available
if ! command -v jq > /dev/null 2>&1; then
    echo "Error: jq is not available. Please install jq to read VERSION.json"
    exit 1
fi

# Extract values from VERSION.json
VERSION=$(jq -r '.version // empty' VERSION.json)
ARM64_URL=$(jq -r '.arm64_url // empty' VERSION.json)
SBRANCH=$(jq -r '.sbranch // "main"' VERSION.json)

if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
    echo "Error: version not found in VERSION.json"
    exit 1
fi

if [ -z "$ARM64_URL" ] || [ "$ARM64_URL" = "null" ]; then
    echo "Error: arm64_url not found in VERSION.json"
    exit 1
fi

echo "Version: $VERSION"
echo "Branch: $SBRANCH"
echo "ARM64 URL: $ARM64_URL"
echo ""

# Check if base image exists locally
if ! docker image inspect distroless-runtime:arm64-debug-local > /dev/null 2>&1; then
    echo "Error: distroless-runtime:arm64-debug-local not found locally"
    echo "Please build it first using: ./distroless-runtime/build-local.sh"
    exit 1
fi

# Build the image with arm64 architecture
# Use docker build (not buildx) for local builds to access local images
echo "Building image..."

if ! docker build \
    --build-arg TARGETARCH=arm64 \
    --build-arg BASE_IMAGE=distroless-runtime:arm64-debug-local \
    --build-arg LIB_DIR=aarch64-linux-gnu \
    --build-arg VERSION="$VERSION" \
    --build-arg ARM64_URL="$ARM64_URL" \
    --build-arg SBRANCH="$SBRANCH" \
    --tag "$TAG" \
    --file dockerfile \
    .; then
    echo ""
    echo "Error: Build failed. Check the output above for details."
    exit 1
fi

echo ""
echo "Build completed successfully!"
echo "Image tagged as: $TAG"
echo ""
echo "To test the image, run:"
echo "  docker run --rm $TAG --help"

