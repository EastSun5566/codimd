#!/usr/bin/env bash

set -eo pipefail
set -x

CURRENT_DIR=$(dirname "${BASH_SOURCE[0]}")

GIT_SHA1="$(git rev-parse HEAD)"
GIT_SHORT_ID="${GIT_SHA1:0:8}"
GIT_TAG=$(git describe --exact-match --tags HEAD 2>/dev/null || true)

DOCKER_TAG="${GIT_TAG:-$GIT_SHORT_ID}"

docker build --target app -t "hackmdio/hackmd:$DOCKER_TAG" -f "$CURRENT_DIR/Dockerfile" "$CURRENT_DIR/.."

