#!/usr/bin/env bash
set -euo pipefail

: "${GCLOUD_PROJECT_ID:?set GCLOUD_PROJECT_ID}"
GCLOUD_REGION="${GCLOUD_REGION:-us-west1}"
FUNCTION_NAME="${FUNCTION_NAME:-gospace}"
WORKSPACE="${WORKSPACE:-$PWD}"
BUNDLE="${BUNDLE:-$WORKSPACE/.bundle}"

PYSPACE_DIR="$WORKSPACE/pyspace"
GOSPACE_DIR="$WORKSPACE/gospace"

[[ -f "$PYSPACE_DIR/main.py" ]] || {
  echo "missing $PYSPACE_DIR; run repo init/repo sync first" >&2
  exit 1
}
[[ -f "$GOSPACE_DIR/gospace/go.mod" ]] || {
  echo "missing $GOSPACE_DIR; run repo init/repo sync first" >&2
  exit 1
}

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/bin"
cp -a "$PYSPACE_DIR"/. "$BUNDLE/"

(
  cd "$GOSPACE_DIR/gospace"
  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -o "$BUNDLE/bin/gospace" ./cmd/api
)
chmod 0755 "$BUNDLE/bin/gospace"

# The Python function is loaded normally. Gospace is registered at function
# initialization, but ProcessSupervisor starts the binary only on the first
# request that falls through from Python to gospace.
gcloud functions deploy "$FUNCTION_NAME" \
  --project "$GCLOUD_PROJECT_ID" \
  --region "$GCLOUD_REGION" \
  --gen1 \
  --runtime python312 \
  --entry-point main \
  --trigger-http \
  --no-allow-unauthenticated \
  --source "$BUNDLE" \
  --set-env-vars 'PYSPACE_GOSPACE_BINARY=/workspace/bin/gospace,PYSPACE_GOSPACE_NAME=gospace'
