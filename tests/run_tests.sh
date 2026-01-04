#!/bin/bash
set -e

# Define root of the repo explicitly
REPO_ROOT="$(pwd)"
TEST_DIR="$REPO_ROOT/tests"

echo "=== Building Test Docker Image (with files copied) ==="
# Build from the root so COPY works correctly
docker build -t dotfiles-test -f "$TEST_DIR/Dockerfile" "$REPO_ROOT"

echo -e "\n=== Running setup.sh inside Docker ==="
docker run --rm -it dotfiles-test

echo -e "\n=== Test Finished ==="
