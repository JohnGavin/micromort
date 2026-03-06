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

# Build ONLY this package, then push ONLY the output path.
# Do NOT use watch-exec (it pushes all new store paths including deps).
# package.nix (buildRPackage) != default.nix (mkShell)
OUT_PATH=$(nix-build package.nix --no-out-link)
echo "Built: $OUT_PATH"
echo "$OUT_PATH" | cachix push $CACHE_NAME

echo "Done."
