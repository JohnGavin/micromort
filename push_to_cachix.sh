#!/usr/bin/env bash
# Push to Cachix script
# See GEMINI.md for details

set -e

if [ -z "$CACHIX_AUTH_TOKEN" ]; then
    echo "Error: CACHIX_AUTH_TOKEN is not set."
    exit 1
fi

CACHE_NAME="johngavin"

# Ensure cachix is installed
if ! command -v cachix &> /dev/null; then
    echo "Error: cachix is not installed."
    exit 1
fi

echo "Pushing built package to $CACHE_NAME..."

# Build and push ONLY the package derivation (not full closure)
cachix watch-exec $CACHE_NAME -- nix-build default.nix --no-out-link

echo "Done."
