#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/release-graphql.sh <environment> <acr_name> [image_tag]

Examples:
  ./scripts/release-graphql.sh dev mskdevacr
  ./scripts/release-graphql.sh dev mskdevacr 2026-03-03.1

Behavior:
  1) Builds runtime/graphql image
  2) Pushes image to <acr_name>.azurecr.io/msk-graphql:<tag>
  3) Runs Terraform deploy with TF_VAR_graphql_container_image set to pushed image
EOF
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage
  exit 1
fi

ENVIRONMENT="$1"
ACR_NAME="$2"
IMAGE_TAG="${3:-$(date +%Y%m%d-%H%M%S)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GRAPHQL_DIR="$REPO_ROOT/runtime/graphql"

IMAGE_REPO="${ACR_NAME}.azurecr.io/msk-graphql"
IMAGE_URI="${IMAGE_REPO}:${IMAGE_TAG}"

if ! command -v az >/dev/null 2>&1; then
  echo "Error: Azure CLI (az) not found in PATH."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker not found in PATH."
  exit 1
fi

if [[ ! -f "$GRAPHQL_DIR/Dockerfile" ]]; then
  echo "Error: GraphQL Dockerfile missing at $GRAPHQL_DIR/Dockerfile"
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "Error: Azure CLI is not authenticated."
  echo "Run: az login && az account set --subscription \"<SUBSCRIPTION_ID>\""
  exit 1
fi

echo "Logging in to ACR: $ACR_NAME"
az acr login -n "$ACR_NAME"

echo "Building image: $IMAGE_URI"
docker build -t "$IMAGE_URI" "$GRAPHQL_DIR"

echo "Pushing image: $IMAGE_URI"
docker push "$IMAGE_URI"

echo "Deploying infra with graphql_container_image=$IMAGE_URI"
(
  cd "$REPO_ROOT"
  TF_VAR_graphql_container_image="$IMAGE_URI" ./scripts/iac.sh "$ENVIRONMENT" infra
)

echo "Release completed."
echo "Container image: $IMAGE_URI"
