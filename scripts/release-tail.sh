#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/release-tail.sh <environment>

Examples:
  ./scripts/release-tail.sh dev
  ./scripts/release-tail.sh stage

Behavior:
  1) Packages runtime/tail Azure Function code
  2) Deploys zip package to fa-msk-tail-<environment>
EOF
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

ENVIRONMENT="$1"
FUNCTION_APP_NAME="fa-msk-tail-${ENVIRONMENT}"
RESOURCE_GROUP_NAME="rg-msk-${ENVIRONMENT}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TAIL_DIR="$REPO_ROOT/runtime/tail"
TMP_DIR="$REPO_ROOT/.tmp"
ZIP_PATH="$TMP_DIR/tail-${ENVIRONMENT}.zip"

if ! command -v az >/dev/null 2>&1; then
  echo "Error: Azure CLI (az) not found in PATH."
  exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "Error: zip not found in PATH."
  exit 1
fi

if [[ ! -f "$TAIL_DIR/host.json" ]]; then
  echo "Error: Tail host.json missing at $TAIL_DIR/host.json"
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "Error: Azure CLI is not authenticated."
  echo "Run: az login && az account set --subscription \"<SUBSCRIPTION_ID>\""
  exit 1
fi

mkdir -p "$TMP_DIR"
rm -f "$ZIP_PATH"

echo "Packaging tail function app"
(
  cd "$TAIL_DIR"
  npm install --omit=dev >/dev/null
  zip -rq "$ZIP_PATH" . -x "*.git*"
)

echo "Deploying function zip to $FUNCTION_APP_NAME"
az functionapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$FUNCTION_APP_NAME" \
  --src "$ZIP_PATH" >/dev/null

echo "Tail function deployed."
